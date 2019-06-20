import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rx_redux/src/reducer.dart';
import 'package:rx_redux/src/reducer_exception.dart';
import 'package:rx_redux/src/side_affect.dart';
import 'package:rxdart/rxdart.dart';

/// A ReduxStore is a RxDart based implementation of Redux and redux-observable.js.org.
///
/// A ReduxStore takes Actions from upstream as input events.
/// [SideEffect]s can be registered to listen for a certain
/// Action to react on a that Action as a (impure) side effect and create yet another Action as
/// output. Every Action goes through the a [Reducer], which is basically a pure function that takes
/// the current State and an Action to compute a new State.
/// The new state will be emitted downstream to any listener interested in it.
///
/// A ReduxStore observable never reaches onDone(). If a error occurs in the [Reducer] or in any
/// side effect (any has been thrown) then the ReduxStore reaches onError() as well and
/// according to the reactive stream specs the store cannot recover the error state.
///
/// * Param [actions] Upstream actions observable
/// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
/// * done lazily once an observer subscribes. The computed initial state will be emitted directly
/// in onListen()
/// * Param [sideEffects] The sideEffects. See [SideEffect]
/// * Param [reducer] The reducer.  See [Reducer].
/// * Param [S] The type of the State
/// * Param [A] The type of the Actions
Observable<S> reduxStore<S, A>({
  @required Stream<A> actions,
  @required S Function() initialStateSupplier,
  @required Iterable<SideEffect<S, A>> sideEffects,
  @required Reducer<S, A> reducer,
}) {
  return Observable(
    actions.transform(
      ReduxStoreStreamTransformer(
        initialStateSupplier: initialStateSupplier,
        reducer: reducer,
        sideEffects: sideEffects,
      ),
    ),
  );
}

class ReduxStoreStreamTransformer<A, S> extends StreamTransformerBase<A, S> {
  final StreamTransformer<A, S> transformer;

  /// * Param [initialStateSupplier]  A function that computes the initial state. The computation is
  /// * done lazily once an observer subscribes. The computed initial state will be emitted directly
  /// in onListen()
  /// * Param [sideEffects] The sideEffects. See [SideEffect]
  /// * Param [reducer] The reducer.  See [Reducer].
  /// * Param [S] The type of the State
  /// * Param [A] The type of the Actions
  ReduxStoreStreamTransformer({
    @required S Function() initialStateSupplier,
    @required Iterable<SideEffect<S, A>> sideEffects,
    @required Reducer<S, A> reducer,
  }) : transformer =
            _buildTransformer<A, S>(initialStateSupplier, sideEffects, reducer);

  @override
  Stream<S> bind(Stream<A> stream) => transformer.bind(stream);

  static StreamTransformer<A, S> _buildTransformer<A, S>(
    S Function() initialStateSupplier,
    Iterable<SideEffect<S, A>> sideEffects,
    Reducer<S, A> reducer,
  ) {
    if (initialStateSupplier == null) {
      throw ArgumentError('initialStateSupplier cannot be null');
    }
    if (sideEffects == null) {
      throw ArgumentError('sideEffects cannot be null');
    }
    if (sideEffects.any((sideEffect) => sideEffect == null)) {
      throw ArgumentError('All sideEffects must be not null');
    }
    if (reducer == null) {
      throw ArgumentError('reducer cannot be null');
    }

    return StreamTransformer<A, S>((
      Stream<A> upstreamActionsStream,
      bool cancelOnError,
    ) {
      final len = sideEffects.length;
      final sideEffectSubscriptions = List<StreamSubscription<A>>(len);

      final actionSubject = PublishSubject<A>();
      final addActionToSubject = actionSubject.add;
      final addErrorToSubject = actionSubject.addError;

      StreamController<S> controller;
      StreamSubscription<A> subscriptionUpstream;
      StreamSubscription<A> subscriptionActionSubject;

      S state;
      final StateAccessor<S> stateAccessor = () => state;
      final onDataActually = (A action) {
        final currentState = state;
        try {
          state = reducer(currentState, action);
          controller.add(state);
        } catch (e, s) {
          controller.addError(
            ReducerException(
              action: action,
              state: currentState,
              error: e,
              stackTrace: s,
            ),
          );
        }
      };
      final onErrorActually = (e, StackTrace s) => controller.addError(e, s);

      controller = StreamController<S>(
        sync: true,
        onListen: () {
          // add initial state
          state = initialStateSupplier();
          controller.add(state);

          // This will make the reducer run on each action
          subscriptionActionSubject = actionSubject.listen(
            onDataActually,
            onError: onErrorActually,
          );

          //listen upstream actions
          subscriptionUpstream = upstreamActionsStream.listen(
            addActionToSubject,
            onError: addErrorToSubject,
            onDone: controller.close,
            cancelOnError: cancelOnError,
          );

          for (int i = 0; i < len; i++) {
            sideEffectSubscriptions[i] = sideEffects.elementAt(i)(
              actionSubject,
              stateAccessor,
            ).listen(
              addActionToSubject,
              onError: addErrorToSubject,
              onDone: () {
                // Swallow onDone because just if one SideEffect reaches onDone we don't want to make
                // everything incl. ReduxStore and other SideEffects reach onDone
              },
              cancelOnError: cancelOnError,
            );
          }
        },
        onPause: ([Future<dynamic> resumeSignal]) {
          [
            subscriptionUpstream,
            ...sideEffectSubscriptions,
            subscriptionActionSubject
          ].forEach((subscription) => subscription.pause(resumeSignal));
        },
        onResume: () {
          [
            subscriptionUpstream,
            ...sideEffectSubscriptions,
            subscriptionActionSubject
          ].forEach((subscription) => subscription.resume());
        },
        onCancel: () async {
          await Future.wait<dynamic>(
            [
              ...sideEffectSubscriptions,
              subscriptionUpstream,
              subscriptionActionSubject,
            ]
                .map((subscription) => subscription.cancel())
                .where((cancelFuture) => cancelFuture != null),
          );
          await actionSubject.close();
        },
      );

      return controller.stream.listen(null);
    });
  }
}
