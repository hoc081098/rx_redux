import 'dart:async';

import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('ReduxStoreStreamTransformer', () {
    test('SideEffects react on upstream Actions but Reducer Reacts first',
        () async {
      final inputs = ['InputAction1', 'InputAction2'];
      final inputActions = Stream.fromIterable(inputs)
          .asyncMap((action) => Future.delayed(Duration.zero, () => action));

      final sideEffect1 = (Stream<String> actions, GetState<String> state) {
        return actions
            .where((action) => inputs.contains(action))
            .map((action) => '${action}SideEffect1');
      };
      final sideEffect2 = (Stream<String> actions, GetState<String> state) {
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
          GetState<String> accessor,
        ) =>
            actions.asyncExpand((_) => Stream<String>.empty());

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
            'Initial' 'Action1',
            'Initial' 'Action1' 'Action2',
            'Initial' 'Action1' 'Action2' 'Action3',
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
              logger: rxReduxDefaultLogger,
            ),
          ),
          emitsInOrder(
            [
              'Initial',
              emitsError(
                const TypeMatcher<ReducerException>()
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

    test('Sync stream', () async {
      final streamController = StreamController<int>.broadcast(sync: true);

      final stateStream = streamController.stream.reduxStore<String>(
        initialStateSupplier: () => '0',
        sideEffects: [],
        reducer: (state, action) => '$state-$action',
        logger: rxReduxDefaultLogger,
      );

      expect(
        stateStream,
        emitsInOrder(
          [
            '0',
            '0-1',
            '0-1-2',
            '0-1-2-3',
          ],
        ),
      );

      streamController.add(1);
      streamController.add(2);
      streamController.add(3);
    });

    test(
      'Disposing reduxStore disposes all side effects and upstream',
      () async {
        var disposedSideffectsCount = 0;
        var outputedError;
        var outputCompleted = false;

        final dummyAction = 'SomeAction';
        final upstream = PublishSubject<String>();
        final outputedStates = <String>[];

        final sideEffect1 = (Stream<String> actions, GetState<String> state) {
          return actions
              .where((a) => a == dummyAction)
              .mapTo('SideEffectAction1')
              .doOnCancel(() => disposedSideffectsCount++);
        };

        final sideEffect2 = (Stream<String> actions, GetState<String> state) {
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

    test('Extension method', () async {
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

    test('InitialStateSupplier throws', () {
      final stream = Stream.value(1).reduxStore<String>(
        initialStateSupplier: () => throw Exception(),
        sideEffects: [],
        reducer: (state, action) => '$state+$action',
      );
      expect(stream, emitsInOrder([emitsError(isException), emitsDone]));
    });

    test('Pause and resume', () {
      final stream = Stream.fromIterable([1, 2, 3, 4])
          .asyncMap((action) => Future(() => action))
          .reduxStore<String>(
            initialStateSupplier: () => 'State',
            sideEffects: [],
            reducer: (state, action) => '$state+$action',
            logger: rxReduxDefaultLogger,
          );

      var i = 0;
      final subscription = stream.listen(
        expectAsync1(
          (state) {
            expect(
              state,
              const [
                'State',
                'State+1',
                'State+1+2',
                'State+1+2+3',
                'State+1+2+3+4',
              ][i++],
            );
          },
          count: 5,
        ),
      );

      subscription
          .pause(Future<void>.delayed(const Duration(milliseconds: 300)));
    });

    test('Get current state in SideEffects', () {
      Stream.fromIterable([1, 2, 3, 4])
          .asyncMap((action) => Future(() => action))
          .reduxStore<String>(
            initialStateSupplier: () => 'State',
            sideEffects: [
              (actions, getState) => actions
                  .where((event) => event == 1)
                  .doOnData(expectAsync1(
                    (_) => expect(getState(), 'State+1'),
                    count: 1,
                  ))
                  .flatMap((value) => Rx.never()),
              (actions, getState) => actions
                  .where((event) => event == 2)
                  .doOnData(expectAsync1(
                    (_) => expect(getState(), 'State+1+2'),
                    count: 1,
                  ))
                  .flatMap((value) => Rx.never()),
              (actions, getState) => actions
                  .where((event) => event == 3)
                  .doOnData(expectAsync1(
                    (_) => expect(getState(), 'State+1+2+3'),
                    count: 1,
                  ))
                  .flatMap((value) => Rx.never()),
              (actions, getState) => actions
                  .where((event) => event == 4)
                  .doOnData(expectAsync1(
                    (_) => expect(getState(), 'State+1+2+3+4'),
                    count: 1,
                  ))
                  .flatMap((value) => Rx.never()),
            ],
            reducer: (state, action) => '$state+$action',
            logger: rxReduxDefaultLogger,
          )
          .listen(null);
    });

    test('Stream.first', () {
      final streamController = StreamController<int>.broadcast(sync: true);

      streamController.add(1);
      streamController.add(2);
      streamController.add(3);

      final reduxStore = streamController.stream.reduxStore<String>(
        initialStateSupplier: () => '0',
        sideEffects: [],
        reducer: (state, action) => '$state$action',
        logger: rxReduxDefaultLogger,
      );
      reduxStore.first.then((value) => expect(value, '0'));

      for (var i = 0; i < 50; i++) {
        streamController.add(4 + i);
      }
    });

    test('Cancel subscription', () async {
      final controller = StreamController(sync: true);

      // ignore: unawaited_futures
      controller.stream
          .reduxStore<String>(
            initialStateSupplier: () => '0',
            sideEffects: [],
            reducer: (state, action) => '$state$action',
            logger: rxReduxDefaultLogger,
          )
          .listen((_) => expect(false, true))
          .cancel();

      controller.add(1);
      controller.add(2);

      await Future.delayed(const Duration(seconds: 1));
    });
  });
}
