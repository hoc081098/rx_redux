import 'package:rx_redux/rx_redux.dart';
import 'package:test/test.dart';

enum _Action { a1, a2, a3, b1, b2, b3, b0 }

void main() {
  group('RxReduxStore', () {
    test('1', () async {
      final store = RxReduxStore<_Action, int>(
        initialState: 0,
        sideEffects: [
          (action, getState) => action
              .where((event) => event == _Action.a1)
              .asyncExpand((event) =>
                  Stream.periodic(const Duration(seconds: 1), (_) => _Action.b1)
                      .take(1)),
          (action, getState) => action
              .where((event) => event == _Action.a2)
              .asyncExpand((event) => Stream.periodic(
                      const Duration(milliseconds: 500), (_) => _Action.b2)
                  .take(1)),
          (action, getState) => action
              .where((event) => event == _Action.a3)
              .asyncExpand((event) => Stream.periodic(
                      const Duration(milliseconds: 300), (_) => _Action.b3)
                  .take(1)),
          (action, getState) => Stream.error(Exception()),
        ],
        reducer: (state, action) {
          switch (action) {
            case _Action.b1:
              return state + 1;
            case _Action.b2:
              return state + 2;
            case _Action.b3:
              return state + 3;
            default:
              return state;
          }
        },
        handleError: (e, s) => print('Oh no $e'),
        logger: rxReduxDefaultLogger,
      );

      await Future.delayed(const Duration(seconds: 1));
      print('<~> [1] ${store.state}');
      final sub = store.stateStream.listen((event) => print('~> [1] $event'));

      store.dispatch(_Action.a1);
      store.dispatch(_Action.a2);
      store.dispatch(_Action.a3);

      await Future.delayed(const Duration(seconds: 1));
      print('<~> [2] ${store.state}');
      final sub2 = store.stateStream.listen((event) => print('~> [2] $event'));

      store.dispatch(_Action.a1);
      store.dispatch(_Action.a2);
      store.dispatch(_Action.a3);

      await Future.delayed(const Duration(seconds: 1));
      store.dispatch(_Action.b0);
      store.dispatch(_Action.b0);
      store.dispatch(_Action.b0);

      await sub.cancel();
      await sub2.cancel();
      await store.dispose();

      print('~> Done');
    });
  });
}
