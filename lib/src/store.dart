import 'dart:async';

import 'package:rx_redux/rx_redux.dart';

///
class Store<A, S> {
  final _action = StreamController<A>.broadcast();

  StreamSubscription _subscription;
  S _state;
  Stream<S> _stateStream;

  ///
  Store(
    S initialState,
    List<SideEffect<A, S>> sideEffects,
    Reducer<A, S> reducer,
    void Function(Object, StackTrace) handleError,
  ) {
    _state = initialState;

    _stateStream = _action.stream.reduxStore<S>(
      initialStateSupplier: () => initialState,
      sideEffects: sideEffects,
      reducer: reducer,
      logger: rxReduxDefaultLogger,
    );

    _subscription = _stateStream.listen(
      (state) => _state = state,
      onError: handleError,
    );
  }

  ///
  Stream<S> get stateStream async* {
    yield _state;
    yield* _stateStream;
  }

  ///
  S get state => _state;

  ///
  void dispatch(A action) => _action.add(action);

  ///
  Future<void> dispose() async {
    await _action.close();
    await _subscription.cancel();
  }
}

enum Action { a1, a2, a3, b1, b2, b3 }

void main() async {
  try {
    final store = Store<Action, int>(
      0,
      [
        (action, getState) => action
            .where((event) => event == Action.a1)
            .asyncExpand((event) =>
                Stream.periodic(const Duration(seconds: 1), (_) => Action.b1)
                    .take(1)),
        (action, getState) => action
            .where((event) => event == Action.a2)
            .asyncExpand((event) => Stream.periodic(
                const Duration(milliseconds: 500), (_) => Action.b2).take(1)),
        (action, getState) => action
            .where((event) => event == Action.a3)
            .asyncExpand((event) => Stream.periodic(
                const Duration(milliseconds: 300), (_) => Action.b3).take(1)),
        (action, getState) {
          return Stream.error(Exception());
        },
      ],
      (state, action) {
        switch (action) {
          case Action.b1:
            return state + 1;
          case Action.b2:
            return state + 2;
          case Action.b3:
            return state + 3;
          default:
            return state;
        }
      },
      (e, s) => print('Oh no $e'),
    );

    await Future.delayed(const Duration(seconds: 1));
    print('<->[1] ${store.state}');
    store.stateStream.listen((event) => print('[1] $event'));

    store.dispatch(Action.a1);
    store.dispatch(Action.a2);
    store.dispatch(Action.a3);

    await Future.delayed(const Duration(seconds: 1));

    store.dispatch(Action.a1);
    store.dispatch(Action.a2);
    store.dispatch(Action.a3);

    print('<->[2] ${store.state}');
    store.stateStream.listen((event) => print('[2] $event'));

    await Future.delayed(const Duration(seconds: 1));

    store.dispatch(Action.a3);
    store.dispatch(Action.a2);
    store.dispatch(Action.a1);

    await store.dispose();
  } catch (e, s) {
    print(s);
  }
}
