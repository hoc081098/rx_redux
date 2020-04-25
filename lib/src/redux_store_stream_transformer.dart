import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rx_redux/src/reducer.dart';
import 'package:rx_redux/src/reducer_exception.dart';
import 'package:rx_redux/src/side_affect.dart';

///
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
  /// * Param [State] The type of the State
  /// * Param [Action] The type of the Actions
  Stream<State> reduxStore<State>({
    @required State Function() initialStateSupplier,
    @required Iterable<SideEffect<State, Action>> sideEffects,
    @required Reducer<State, Action> reducer,
  }) {
    return transform(
      ReduxStoreStreamTransformer(
        initialStateSupplier: initialStateSupplier,
        reducer: reducer,
        sideEffects: sideEffects,
      ),
    );
  }
}

///
class ReduxStoreStreamTransformer<Action, State>
    extends StreamTransformerBase<Action, State> {
  final State Function() _initialStateSupplier;
  final Iterable<SideEffect<State, Action>> _sideEffects;
  final Reducer<State, Action> _reducer;

  /// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
  /// * done lazily once an observer subscribes. The computed initial state will be emitted directly
  /// in onListen()
  /// * Param [sideEffects] The sideEffects. See [SideEffect]
  /// * Param [reducer] The reducer.  See [Reducer].
  /// * Param [State] The type of the State
  /// * Param [Action] The type of the Actions
  ReduxStoreStreamTransformer({
    @required State Function() initialStateSupplier,
    @required Iterable<SideEffect<State, Action>> sideEffects,
    @required Reducer<State, Action> reducer,
  })  : assert(initialStateSupplier != null,
            'initialStateSupplier cannot be null'),
        assert(sideEffects != null, 'sideEffects cannot be null'),
        assert(reducer != null, 'reducer cannot be null'),
        _initialStateSupplier = initialStateSupplier,
        _sideEffects = sideEffects,
        _reducer = reducer;

  @override
  Stream<State> bind(Stream<Action> stream) {
    final actionController = StreamController<Action>.broadcast();
    final addActionToController = actionController.add;
    final addErrorToController = actionController.addError;

    StreamController<State> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];

    State state;
    final stateAccessor = () => state;

    onActionData(Action action) {
      final currentState = state;
      try {
        state = _reducer(currentState, action);
        controller.add(state);
      } catch (e, s) {
        controller.addError(
          ReducerException<Action, State>(
            action: action,
            state: currentState,
            error: e,
            stackTrace: s,
          ),
        );
      }
    }

    onActionError(e, StackTrace s) => controller.addError(e, s);

    onDone() {
      if (!controller.isClosed) {
        controller.close();
      }
      if (!actionController.isClosed) {
        actionController.close();
      }
    }

    onListen() {
      try {
        // add initial state
        state = _initialStateSupplier();
        controller.add(state);

        // This will make the reducer run on each action
        subscriptions.add(
          actionController.stream.listen(
            onActionData,
            onError: onActionError,
          ),
        );

        // Listen to upstream actions
        subscriptions.add(
          stream.listen(
            addActionToController,
            onError: addErrorToController,
            onDone: onDone,
          ),
        );

        // Listen to side effect streams
        final sideEffectSubscriptions = _sideEffects.map((sideEffect) {
          if (sideEffect == null) {
            return null;
          }
          return sideEffect(
            actionController.stream,
            stateAccessor,
          ).listen(
            addActionToController,
            onError: addErrorToController,
            onDone: () {
              // Swallow onDone because just if one SideEffect reaches onDone we don't want to make
              // everything incl. ReduxStore and other SideEffects reach onDone
            },
          );
        }).where((subscription) => subscription != null);
        subscriptions.addAll(sideEffectSubscriptions);
      } catch (e, s) {
        onActionError(e, s);
      }
    }

    onCancel() {
      final futures = subscriptions
          .map((subscription) => subscription.cancel())
          .where((cancelFuture) => cancelFuture != null);
      return futures.isEmpty ? null : Future.wait(futures);
    }

    controller = StreamController<State>(
      sync: true,
      onListen: onListen,
      onPause: ([Future resumeSignal]) => subscriptions
          .forEach((subscription) => subscription.pause(resumeSignal)),
      onResume: () =>
          subscriptions.forEach((subscription) => subscription.resume()),
      onCancel: onCancel,
    );

    return controller.stream;
  }
}
