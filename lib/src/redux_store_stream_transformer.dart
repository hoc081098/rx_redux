import 'dart:async';

import 'logger.dart';
import 'reducer.dart';
import 'reducer_exception.dart';
import 'side_effect.dart';
import 'utils.dart';
import 'wrapper_action.dart';

/// Redux store stream Extension for Stream of actions.
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
    required State Function() initialStateSupplier,
    required Iterable<SideEffect<Action, State>> sideEffects,
    required Reducer<Action, State> reducer,
    RxReduxLogger? logger,
  }) =>
      transform(
        ReduxStoreStreamTransformer(
          initialStateSupplier: initialStateSupplier,
          reducer: reducer,
          sideEffects: sideEffects,
          logger: logger,
        ),
      );
}

/// Transform stream of actions to stream of states.
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
class ReduxStoreStreamTransformer<A, S> extends StreamTransformerBase<A, S> {
  final S Function() _initialStateSupplier;
  final Iterable<SideEffect<A, S>> _sideEffects;
  final Reducer<A, S> _reducer;
  final RxReduxLogger? _logger;

  /// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
  /// * done lazily once an observer subscribes. The computed initial state will be emitted directly
  /// in onListen()
  /// * Param [sideEffects] The sideEffects. See [SideEffect]
  /// * Param [reducer] The reducer.  See [Reducer].
  /// * Param [logger] The logger that logs messages.
  /// * Param [S] The type of the State
  /// * Param [A] The type of the Actions
  ReduxStoreStreamTransformer({
    required S Function() initialStateSupplier,
    required Iterable<SideEffect<A, S>> sideEffects,
    required Reducer<A, S> reducer,
    RxReduxLogger? logger,
  })  : _initialStateSupplier = initialStateSupplier,
        _sideEffects = sideEffects,
        _reducer = reducer,
        _logger = logger;

  @override
  Stream<S> bind(Stream<A> stream) {
    late StreamController<S> controller;
    List<StreamSubscription<dynamic>>? subscriptions;
    StreamController<WrapperAction>? _actionController;

    void onListen() {
      S state;

      try {
        state = _initialStateSupplier();
      } catch (e, s) {
        controller.addError(e, s);
        controller.close();
        return;
      }

      void onDataActually(WrapperAction wrapper) {
        final type = wrapper.type;
        final currentState = state;

        // add initial state
        if (identical(wrapper, WrapperAction.initial)) {
          final message = '\n'
              '  ⟶ Action       : $type\n'
              '  ⟹ Current state: $currentState';
          _logger?.call(message);
          return controller.add(currentState);
        }

        final action = wrapper.action<A>();
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

      final actionController =
          _actionController = StreamController<WrapperAction>.broadcast();

      // Call reducer on each action.
      final subscriptionActionController =
          actionController.stream.listen(onDataActually);

      // Add initial action
      actionController.add(WrapperAction.initial);

      // Listening to upstream actions
      final subscriptionUpstream =
          stream.map((action) => WrapperAction.external(action)).listen(
                actionController.add,
                onError: controller.addError,
                onDone: controller.close,
              );

      final getState = () => state;
      final actionStream = actionController.stream
          .map((wrapper) => wrapper.action<A>())
          .asBroadcastStream(onCancel: (s) => s.cancel());

      subscriptions = [
        ..._listenSideEffects(
            actionController, getState, controller, actionStream),
        subscriptionUpstream,
        subscriptionActionController,
      ];
    }

    Future<void> onCancel() async {
      final future = _actionController?.close();
      final cancelFutures = subscriptions?.map((s) => s.cancel());
      final futures = [...?cancelFutures, if (future != null) future];

      if (futures.isNotEmpty) {
        await Future.wait<void>(futures);
      }
      _logger?.call('Cancelled');
    }

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
        onPause: () => subscriptions?.forEach((s) => s.pause()),
        onResume: () => subscriptions?.forEach((s) => s.resume()),
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }

  Iterable<StreamSubscription<dynamic>> _listenSideEffects(
    StreamController<WrapperAction> actionController,
    GetState<S> getState,
    StreamController<S> stateController,
    Stream<A> actionStream,
  ) {
    return _sideEffects.mapIndexed(
      (index, sideEffect) {
        Stream<A> actions;
        try {
          actions = sideEffect(actionStream, getState);
        } catch (e, s) {
          actions = Stream.error(e, s);
        }

        return actions
            .map((action) => WrapperAction.sideEffect(action, index))
            .listen(
              actionController.add,
              onError: stateController.addError,
              // Swallow onDone because just if one SideEffect reaches onDone
              // we don't want to make everything incl. ReduxStore and other SideEffects reach onDone
            );
      },
    );
  }
}
