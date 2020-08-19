import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rx_redux/rx_redux.dart';

import 'reducer.dart';
import 'reducer_exception.dart';
import 'side_effect.dart';

/// TODO
extension ReduxStoreExt<Action> on Stream<Action> {
  /// A ReduxStore is a RxDart based implementation of Redux and redux-observable.js.org.
  ///
  /// A ReduxStore takes Actions from upstream as input events.
  /// [SideEffect]s can be registered to listen for a certain
  /// Action to react on a that Action as a (impure) side effect and create yet another Action as
  /// output. Every Action goes through the a [Reducer], which is basically a pure function that takes
  /// the current State and an Action to compute a new State.
  /// The new state will be emitted downstream to any listener interested in it.
  ///
  /// A ReduxStore stream never reaches onDone(). If a error occurs in the [Reducer] or in any
  /// side effect (any has been thrown) then the ReduxStore reaches onError() as well and
  /// according to the reactive stream specs the store cannot recover the error state.
  ///
  /// * Param [actions] Upstream actions stream
  /// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
  /// * done lazily once an observer subscribes. The computed initial state will be emitted directly
  /// in onListen()
  /// * Param [sideEffects] The sideEffects. See [SideEffect]
  /// * Param [reducer] The reducer.  See [Reducer].
  /// * Param [logger] The logger that logs messages.
  /// * Param [State] The type of the State
  /// * Param [Action] The type of the Actions
  Stream<State> reduxStore<State>({
    @required State Function() initialStateSupplier,
    @required Iterable<SideEffect<Action, State>> sideEffects,
    @required Reducer<Action, State> reducer,
    RxReduxLogger logger,
  }) {
    return transform(
      ReduxStoreStreamTransformer(
        initialStateSupplier: initialStateSupplier,
        reducer: reducer,
        sideEffects: sideEffects,
        logger: logger,
      ),
    );
  }
}

/// TODO
class ReduxStoreStreamTransformer<A, S> extends StreamTransformerBase<A, S> {
  final S Function() _initialStateSupplier;
  final Iterable<SideEffect<A, S>> _sideEffects;
  final Reducer<A, S> _reducer;
  final RxReduxLogger _logger;

  /// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
  /// * done lazily once an observer subscribes. The computed initial state will be emitted directly
  /// in onListen()
  /// * Param [sideEffects] The sideEffects. See [SideEffect]
  /// * Param [reducer] The reducer.  See [Reducer].
  /// * Param [logger] The logger that logs messages.
  /// * Param [S] The type of the State
  /// * Param [A] The type of the Actions
  ReduxStoreStreamTransformer({
    @required S Function() initialStateSupplier,
    @required Iterable<SideEffect<A, S>> sideEffects,
    @required Reducer<A, S> reducer,
    RxReduxLogger logger,
  })  : assert(initialStateSupplier != null,
            'initialStateSupplier cannot be null'),
        assert(sideEffects != null, 'sideEffects cannot be null'),
        assert(sideEffects.every((sideEffect) => sideEffect != null),
            'All sideEffects must be not null'),
        assert(reducer != null, 'reducer cannot be null'),
        _initialStateSupplier = initialStateSupplier,
        _sideEffects = sideEffects,
        _reducer = reducer,
        _logger = logger;

  @override
  Stream<S> bind(Stream<A> stream) {
    StreamController<S> controller;
    List<StreamSubscription<dynamic>> subscriptions;
    StreamController<_WrapperAction<A>> actionController;

    void onListen() {
      S state;

      try {
        state = _initialStateSupplier();
      } catch (e, s) {
        controller.addError(e, s);
        controller.close();
        return;
      }

      void onDataActually(_WrapperAction<A> wrapper) {
        final action = wrapper.action;
        final type = wrapper.type;
        final currentState = state;

        // add initial state
        if (type == _ActionType.initial) {
          final message = '\n'
              '  ⟶ Action       : $type\n'
              '  ⟹ Current state: $currentState';
          _logger?.call(message);
          return controller.add(currentState);
        }

        try {
          final newState = _reducer(currentState, action);
          controller.add(newState);
          state = newState;

          final message = '\n'
              '  ⟶ Action       : $type ↭ $action\n'
              '  ⟶ Current state: $currentState\n'
              '  ⟹ New state    : $newState';
          _logger?.call(message);
        } catch (e, s) {
          controller.addError(
            ReducerException<A, S>(
              action: action,
              state: currentState,
              error: e,
              stackTrace: s,
            ),
          );

          final message = '\n'
              '  ⟶ Action       : $type ↭ $action\n'
              '  ⟶ Current state: $currentState\n'
              '  ⟹ Error        : $e ↭ $s';
          _logger?.call(message);
        }
      }

      actionController = StreamController<_WrapperAction<A>>.broadcast();

      // Call reducer on each action.
      final subscriptionActionController =
          actionController.stream.listen(onDataActually);

      // Add initial action
      actionController.add(_WrapperAction(null, _ActionType.initial));

      // Listening to upstream actions
      final subscriptionUpstream = stream
          .map((action) => _WrapperAction(action, _ActionType.external))
          .listen(
            actionController.add,
            onError: controller.addError,
            onDone: controller.close,
          );

      final getState = () => state;

      subscriptions = [
        ..._listenSideEffects(actionController, getState, controller),
        subscriptionUpstream,
        subscriptionActionController
      ];
    }

    final onCancel = () async {
      final futures = subscriptions?.map((s) => s.cancel());
      if (futures?.isNotEmpty == true) {
        await Future.wait(futures);
      }
      final future = actionController?.close();
      if (future != null) {
        await future;
      }
      _logger?.call('Cancelled');
    };

    if (stream.isBroadcast) {
      controller = StreamController<S>.broadcast(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<S>(
        sync: true,
        onListen: onListen,
        onPause: () => subscriptions.forEach((s) => s.pause()),
        onResume: () => subscriptions.forEach((s) => s.resume()),
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }

  Iterable<StreamSubscription<dynamic>> _listenSideEffects(
    StreamController<_WrapperAction<A>> actionController,
    GetState<S> getState,
    StreamController<S> controller,
  ) {
    return _sideEffects.mapIndexed(
      (index, sideEffect) => sideEffect(
              actionController.stream.map((wrapper) => wrapper.action),
              getState)
          .map(
              (action) => _WrapperAction(action, _ActionType.sideEffect(index)))
          .listen(
            actionController.add,
            onError: controller.addError,
            // Swallow onDone because just if one SideEffect reaches onDone
            // we don't want to make everything incl. ReduxStore and other SideEffects reach onDone
          ),
    );
  }
}

//
// Internal
//

@sealed
abstract class _ActionType {
  const _ActionType.empty();

  static const initial = _Initial();
  static const external = _External();

  const factory _ActionType.sideEffect(int index) = _SideEffect;

  @override
  String toString() {
    if (this is _Initial) {
      return '⭍';
    }
    if (this is _External) {
      return '↓';
    }
    if (this is _SideEffect) {
      return '⟳${(this as _SideEffect).index}';
    }
    throw StateError('Unknown $this');
  }
}

class _Initial extends _ActionType {
  const _Initial() : super.empty();
}

class _External extends _ActionType {
  const _External() : super.empty();
}

class _SideEffect extends _ActionType {
  final int index;

  const _SideEffect(this.index) : super.empty();
}

class _WrapperAction<A> {
  final A action;
  final _ActionType type;

  _WrapperAction(this.action, this.type);
}

extension _MapIndexedIterableExtensison<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) {
    var index = 0;
    return map((t) => mapper(index++, t));
  }
}
