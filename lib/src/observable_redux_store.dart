import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rx_redux/src/reducer.dart';
import 'package:rx_redux/src/reducer_exception.dart';
import 'package:rx_redux/src/side_affect.dart';
import 'package:rxdart/rxdart.dart';

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

  ReduxStoreStreamTransformer({
    @required S Function() initialStateSupplier,
    @required Iterable<SideEffect<S, A>> sideEffects,
    @required Reducer<S, A> reducer,
  })  : assert(initialStateSupplier != null),
        assert(sideEffects != null),
        assert(reducer != null),
        transformer =
            _buildTransformer<A, S>(initialStateSupplier, sideEffects, reducer);

  @override
  Stream<S> bind(Stream<A> stream) => transformer.bind(stream);

  static StreamTransformer<A, S> _buildTransformer<A, S>(
    S Function() initialStateSupplier,
    Iterable<SideEffect<S, A>> sideEffects,
    Reducer<S, A> reducer,
  ) {
    return StreamTransformer<A, S>((
      Stream<A> upstreamActionsStream,
      bool cancelOnError,
    ) {
      final CompositeSubscription compositeSubscription =
          CompositeSubscription();
      final PublishSubject<A> actionsSubject = PublishSubject<A>();

      StreamController<S> controller;
      StreamSubscription<A> subscription;

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
      final onDoneActually = () => controller.close();

      controller = StreamController<S>(
        sync: true,
        onListen: () {
          state = initialStateSupplier();
          controller.add(state);

          compositeSubscription
            ..add(
              subscription = upstreamActionsStream.listen(
                actionsSubject.add,
                onError: actionsSubject.addError,
                onDone: actionsSubject.close,
                cancelOnError: cancelOnError,
              ),
            )
            ..add(
              actionsSubject.listen(
                onDataActually,
                onError: onErrorActually,
                onDone: onDoneActually,
              ),
            );

          sideEffects.map((sideEffect) {
            return sideEffect(
              actionsSubject,
              stateAccessor,
            ).listen(
              actionsSubject.add,
              onError: actionsSubject.addError,
            );
          }).forEach(compositeSubscription.add);
        },
        onPause: ([Future<dynamic> resumeSignal]) =>
            subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: () => compositeSubscription.dispose(),
      );

      return controller.stream.listen(null);
    });
  }
}
