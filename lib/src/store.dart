import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';

import '../rx_redux.dart';

/// Rx Redux Store.
/// Redux store based on [Stream].
class RxReduxStore<A, S> {
  final void Function(A) _dispatch;

  final GetState<S> _getState;
  final Stream<S> Function() _stateStream;

  final Future<void> Function() _dispose;

  const RxReduxStore._(
    this._dispatch,
    this._getState,
    this._stateStream,
    this._dispose,
  );

  /// Construct a [RxReduxStore]
  factory RxReduxStore({
    @required S initialState,
    @required List<SideEffect<A, S>> sideEffects,
    @required Reducer<A, S> reducer,
    void Function(Object, StackTrace) handleError,
    bool Function(S previous, S next) equals,
    RxReduxLogger logger,
  }) {
    final actionSubject = StreamController<A>.broadcast(sync: true);

    final stateStream = actionSubject.stream.reduxStore<S>(
      initialStateSupplier: () => initialState,
      sideEffects: sideEffects,
      reducer: reducer,
      logger: logger,
    );

    var currentState = initialState;

    return RxReduxStore._(
      actionSubject.add,
      () => currentState,
      () => () async* {
        yield currentState;
        yield* stateStream;
      }()
          .distinct(equals),
      DisposeBag(
        [
          stateStream.listen(
            (newState) => currentState = newState,
            onError: handleError,
          ),
          actionSubject
        ],
        false,
      ).dispose,
    );
  }

  /// Get stream of states.
  ///
  /// The stream skips states if they are equal to the previous state.
  /// Equality is determined by the provided [equals] method. If that is omitted,
  /// the '==' operator is used.
  Stream<S> get stateStream => _stateStream();

  /// Get current state synchronously.
  S get state => _getState();

  /// Dispatch action to store.
  void dispatch(A action) => _dispatch(action);

  /// Dispose all resources.
  Future<void> dispose() => _dispose();
}
