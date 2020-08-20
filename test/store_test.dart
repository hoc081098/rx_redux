import 'package:rx_redux/rx_redux.dart';
import 'package:test/test.dart';

enum Action {
  action1,
  action2,
  action3,
  actionSideEffect1,
  actionSideEffect2,
  actionSideEffect3,
  actionNoOp
}

Future<void> delay(int millis) =>
    Future.delayed(Duration(milliseconds: millis));

void main() {
  group('RxReduxStore', () {
    test('Get initialState', () {
      final store = RxReduxStore<Action, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s,
      );
      expect(store.state, 0);
    });

    test('Get current state', () async {
      final store = RxReduxStore<int, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s + a,
      );
      expect(store.state, 0);

      store.dispatch(1);
      await delay(100);
      expect(store.state, 1);

      store.dispatch(10);
      await delay(100);
      expect(store.state, 11);

      store.dispatch(-11);
      await delay(100);
      expect(store.state, 0);
    });

    test('Get state stream that emits initial state', () {
      final store = RxReduxStore<int, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s + a,
      );

      expect(store.stateStream, emits(0));
    });

    test('Get state stream', () async {
      final store = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => '$s+$a',
      );

      final future = expectLater(
        store.stateStream,
        emitsInOrder(
          [
            '0',
            '0+1',
            '0+1+2',
            '0+1+2+3',
          ],
        ),
      );

      await delay(100);

      store.dispatch(1);
      store.dispatch(2);
      store.dispatch(3);

      await future;
      expect(store.stateStream, emits('0+1+2+3'));
    });

    test('Get state stream with SideEffects', () async {
      final store = RxReduxStore<Action, int>(
        initialState: 0,
        sideEffects: [
          (action, getState) => action
              .where((event) => event == Action.action1)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 100),
                  (_) => Action.actionSideEffect1).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action2)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 200),
                  (_) => Action.actionSideEffect2).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action3)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 300),
                  (_) => Action.actionSideEffect3).take(1)),
        ],
        reducer: (state, action) {
          switch (action) {
            case Action.actionSideEffect1:
              return state + 1;
            case Action.actionSideEffect2:
              return state + 2;
            case Action.actionSideEffect3:
              return state + 3;
            default:
              return state;
          }
        },
      );

      expect(
        store.stateStream,
        emitsInOrder(
          [
            0,
            1,
            3,
            6,
            7,
            9,
            12,
          ],
        ),
      );
      expect(store.state, 0);

      await Future.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future.delayed(const Duration(seconds: 1));

      expect(store.state, 6);
      expect(
        store.stateStream,
        emitsInOrder(
          [
            6,
            7,
            9,
            12,
          ],
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future.delayed(const Duration(seconds: 1));

      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Dispose', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => s,
      );

      await rxReduxStore.dispose();

      rxReduxStore.stateStream.listen(
        expectAsync1(
          (v) => expect(v, '0'),
          count: 1,
        ),
        onDone: expectAsync0(
          () {},
          count: 1,
        ),
      );
    });

    test('Error handler called when reducer throws', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => throw Exception(),
        errorHandler: (e, s) => expect(e, isException),
      );

      rxReduxStore.dispatch(1);
    });

    test('Error handler called when SideEffect throws', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [(actions, getState) => throw Exception()],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      );

      rxReduxStore.dispatch(1);
    });

    test('Error handler called when SideEffect returns error Stream', () async {
      RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [(actions, getState) => Stream.error(Exception())],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      ).dispatch(1);

      RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [
          (actions, getState) => actions
              .where((event) => event == 2)
              .asyncExpand((_) => Stream<int>.error(Exception()))
        ],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      )
        ..dispatch(1)
        ..dispatch(2);
    });
  });
}
