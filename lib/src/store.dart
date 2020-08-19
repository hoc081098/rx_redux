import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rx_redux/rx_redux.dart';

/// Rx Redux Store.
/// Redux store based on [Stream].
class Store<A, S> {
  final _action = StreamController<A>.broadcast();

  StreamSubscription _subscription;
  S _state;
  Stream<S> _stateStream;
  bool Function(S previous, S next) _equals;

  /// Construct a [Store]
  Store({
    @required S initialState,
    @required List<SideEffect<A, S>> sideEffects,
    @required Reducer<A, S> reducer,
    void Function(Object, StackTrace) handleError,
    bool Function(S previous, S next) equals,
    RxReduxLogger logger,
  }) {
    _state = initialState;
    _equals = equals;

    _stateStream = _action.stream.reduxStore<S>(
      initialStateSupplier: () => initialState,
      sideEffects: sideEffects,
      reducer: reducer,
      logger: logger,
    );

    _subscription = _stateStream.listen(
      (state) => _state = state,
      onError: handleError,
    );
  }

  /// Get stream of states.
  ///
  /// The stream skips states if they are equal to the previous state.
  /// Equality is determined by the provided [equals] method. If that is omitted,
  /// the '==' operator is used.
  Stream<S> get stateStream {
    final stream = () async* {
      yield _state;
      yield* _stateStream;
    }();
    return stream.distinct(_equals);
  }

  /// Get current state synchronously.
  S get state => _state;

  /// Dispatch action to store.
  void dispatch(A action) => _action.add(action);

  /// Dispose all resources.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _action.close();
  }
}

enum _Action { a1, a2, a3, b1, b2, b3, b0 }

void main() async {
  final store = Store<_Action, int>(
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
              const Duration(milliseconds: 500), (_) => _Action.b2).take(1)),
      (action, getState) => action
          .where((event) => event == _Action.a3)
          .asyncExpand((event) => Stream.periodic(
              const Duration(milliseconds: 300), (_) => _Action.b3).take(1)),
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
  );

  await Future.delayed(const Duration(seconds: 1));
  print('<~> [1] ${store.state}');
  final sub = store.stateStream.listen((event) => print('~> [1] $event'));

  store.dispatch(_Action.a1);
  store.dispatch(_Action.a2);
  store.dispatch(_Action.a3);

  await Future.delayed(const Duration(seconds: 1));

  store.dispatch(_Action.a1);
  store.dispatch(_Action.a2);
  store.dispatch(_Action.a3);

  await Future.delayed(const Duration(seconds: 1));
  store.dispatch(_Action.b0);
  store.dispatch(_Action.b0);
  store.dispatch(_Action.b0);

  print('dispose');
  await sub.cancel();
  await store.dispose();
}
