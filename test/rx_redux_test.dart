import 'dart:async';

import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('Test rx_redux', () {
    test('SideEffects react on upstream Actions but Reducer Reacts first',
        () async {
      final inputs = ['InputAction1', 'InputAction2'];
      final inputActions = Stream.fromIterable(inputs)
          .asyncMap((action) => Future.delayed(Duration.zero, () => action))
          .concatWith([Stream<String>.empty().delay(Duration.zero)]);

      final SideEffect<String, String> sideEffect1 = (actions, state) {
        return actions
            .where((action) => inputs.contains(action))
            .map((action) => '${action}SideEffect1');
      };
      final SideEffect<String, String> sideEffect2 = (actions, state) {
        return actions
            .where((action) => inputs.contains(action))
            .map((action) => '${action}SideEffect2');
      };

      await expectLater(
        inputActions.transform(
          ReduxStoreStreamTransformer(
            initialStateSupplier: () => 'InitialState',
            sideEffects: [sideEffect1, sideEffect2],
            reducer: (currentState, action) => action,
          ),
        ),
        emitsInOrder([
          'InitialState',
          'InputAction1',
          'InputAction1SideEffect1',
          'InputAction1SideEffect2',
          'InputAction2',
          'InputAction2SideEffect1',
          'InputAction2SideEffect2',
          emitsDone,
        ]),
      );
    });

    test('Empty upstream just emits initial state and completes', () async {
      final upstream = Stream<String>.empty();
      await expectLater(
        upstream.transform(
          ReduxStoreStreamTransformer<String, String>(
            initialStateSupplier: () => 'InitialState',
            sideEffects: [],
            reducer: (currentState, action) => currentState,
          ),
        ),
        emitsInOrder(
          [
            'InitialState',
            emitsDone,
          ],
        ),
      );
    });

    test(
      'Error upstream just emits initial state and run in onError',
      () async {
        final upstream = Stream<String>.error('FakeError');
        await expectLater(
          upstream.transform(
            ReduxStoreStreamTransformer<String, String>(
              initialStateSupplier: () => 'InitialState',
              sideEffects: [],
              reducer: (currentState, action) => currentState,
            ),
          ),
          emitsInOrder(
            [
              'InitialState',
              emitsError(
                const TypeMatcher<String>()
                    .having((e) => e, 'Error', 'FakeError'),
              ),
            ],
          ),
        );
      },
    );

    test(
      'SideEffect that returns no Action is supported',
      () async {
        Stream<String> returnNoActionEffect(
          Stream<String> actions,
          StateAccessor<String> accessor,
        ) =>
            actions.flatMap((_) => Stream<String>.empty());

        final upstream = Stream.fromIterable([
          'Action1',
          'Action2',
          'Action3',
        ]);
        await expectLater(
          upstream.transform(
            ReduxStoreStreamTransformer<String, String>(
              initialStateSupplier: () => 'Initial',
              sideEffects: [returnNoActionEffect],
              reducer: (currentState, action) => currentState + action,
            ),
          ),
          emitsInOrder([
            'Initial',
            'Initial' + 'Action1',
            'Initial' + 'Action1' + 'Action2',
            'Initial' + 'Action1' + 'Action2' + 'Action3',
          ]),
        );
      },
    );

    test(
      'Error in reducer enhanced with state and action',
      () async {
        final upstream = Stream.value('Action1');
        final error = StateError('FakeError');

        await expectLater(
          upstream.transform(
            ReduxStoreStreamTransformer<String, String>(
              initialStateSupplier: () => 'Initial',
              sideEffects: [],
              reducer: (_, __) => throw error,
            ),
          ),
          emitsInOrder(
            [
              'Initial',
              emitsError(
                const TypeMatcher<ReducerException<String, String>>()
                    .having(
                      (e) => e.action,
                      'ReducerException.action',
                      const TypeMatcher<String>()
                          .having((a) => a, 'Action', 'Action1'),
                    )
                    .having(
                      (e) => e.state,
                      'ReducerException.state',
                      const TypeMatcher<String>().having(
                        (s) => s,
                        'Current state',
                        'Initial',
                      ),
                    )
                    .having(
                      (e) => e.error,
                      'ReducerException.error',
                      const TypeMatcher<StateError>().having(
                        (s) => s.message,
                        'Caused error message',
                        'FakeError',
                      ),
                    ),
              ),
              emitsDone,
            ],
          ),
        );
      },
    );

    test(
      'Disposing reduxStore disposes all side effects and upstream',
      () async {
        var disposedSideffectsCount = 0;
        var outputedError;
        var outputCompleted = false;

        final dummyAction = 'SomeAction';
        final upstream = PublishSubject<String>();
        final outputedStates = <String>[];

        final SideEffect<String, String> sideEffect1 = (actions, state) {
          return actions
              .where((a) => a == dummyAction)
              .mapTo('SideEffectAction1')
              .doOnCancel(() => disposedSideffectsCount++);
        };

        final SideEffect<String, String> sideEffect2 = (actions, state) {
          return actions
              .where((a) => a == dummyAction)
              .mapTo('SideEffectAction2')
              .doOnCancel(() => disposedSideffectsCount++);
        };

        final subscription = upstream
            .transform(
              ReduxStoreStreamTransformer<String, String>(
                initialStateSupplier: () => 'InitialState',
                sideEffects: [sideEffect1, sideEffect2],
                reducer: (state, action) => action,
              ),
            )
            .listen(
              outputedStates.add,
              onError: (e, s) => outputedError = e,
              onDone: () => outputCompleted = true,
            );

        // I know it's bad, but it does the job
        await Future.delayed(const Duration(milliseconds: 100));

        // Trigger some action
        upstream.add(dummyAction);

        // I know it's bad, but it does the job
        await Future.delayed(const Duration(milliseconds: 100));

        // Dispose the whole cain
        await subscription.cancel();

        // I know it's bad, but it does the job
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify everything is fine
        expect(disposedSideffectsCount, 2);
        expect(upstream.hasListener, false);
        expect(
          outputedStates,
          [
            'InitialState',
            dummyAction,
            'SideEffectAction1',
            'SideEffectAction2',
          ],
        );
        expect(outputedError, isNull);
        expect(outputCompleted, false);
      },
    );

    test('Broadcast stream', () async {
      final state = Stream.fromIterable([1, 2, 3, 4])
          .transform(
            ReduxStoreStreamTransformer<int, String>(
              initialStateSupplier: () => '[]',
              reducer: (String currentState, int newAction) {
                return currentState * newAction;
              },
              sideEffects: [],
            ),
          )
          .asBroadcastStream();

      state.listen(null);
      state.listen(null);

      expect(true, true);
    });

    test('extension method', () async {
      final state = Stream.periodic(const Duration(seconds: 1), (i) => i)
          .take(2)
          .reduxStore<String>(
            initialStateSupplier: () => 'State',
            sideEffects: [],
            reducer: (state, action) => '$state$action',
          );
      await expectLater(
        state,
        emitsInOrder([
          'State',
          'State0',
          'State01',
        ]),
      );
    });
  });
}
