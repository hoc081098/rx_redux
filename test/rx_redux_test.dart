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
          .asyncMap((action) => Future.delayed(Duration.zero, () => action));

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
      '`Error upstream just emits initial state and run in onError',
      () async {
        final upstream = Observable<String>.error('FakeError');
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
  });
}
