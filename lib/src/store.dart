import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import 'logger.dart';
import 'reducer.dart';
import 'redux_store_stream_transformer.dart';
import 'side_effect.dart';

/// A [SideEffect] that returns a never-completed Stream and on each action received,
/// adding it to [outputSink].
SideEffect<A, S> _onEachActionSideEffect<A, S>(StreamSink<A> outputSink) {
  return (actions, _) {
    final neverController = StreamController<A>();
    late StreamSubscription<A> subscription;

    neverController.onListen =
        () => subscription = actions.listen(outputSink.add);
    neverController.onCancel = () async {
      await subscription.cancel();
      await outputSink.close();
    };

    return neverController.stream;
  };
}

extension _StreamExtension<S> on Stream<S> {
  Stream<S> handleErrorIfNeeded(
          void Function(Object, StackTrace)? errorHandler) =>
      errorHandler == null ? this : handleError(errorHandler);
}

/// Rx Redux Store.
/// Redux store based on [Stream].
class RxReduxStore<A, S> {
  final void Function(A) _dispatch;

  final DistinctValueStream<S> _stateStream;
  final Stream<A> _actionStream;

  final DisposeBag _bag;

  const RxReduxStore._(
    this._dispatch,
    this._stateStream,
    this._actionStream,
    this._bag,
  );

  /// Construct a [RxReduxStore]
  ///
  /// The [errorHandler] used to handle error emitted from upstream.
  /// If [errorHandler] is omitted, any errors on upstream are considered unhandled,
  /// and will be passed to the current [Zone]'s error handler.
  /// By default unhandled async errors are treated as if they were uncaught top-level errors.
  ///
  /// The [equals] used to determine equality between old and new states.
  /// If calling it returns true, the new state will not be emitted.
  /// If [equals] is omitted, the '==' operator is used.
  /// If [equals] is provided, calling it must not throw any errors.
  factory RxReduxStore({
    required S initialState,
    required List<SideEffect<A, S>> sideEffects,
    required Reducer<A, S> reducer,
    void Function(Object, StackTrace)? errorHandler,
    bool Function(S previous, S next)? equals,
    RxReduxLogger? logger,
  }) {
    final actionController = StreamController<A>(sync: true);
    final actionOutputController = StreamController<A>.broadcast(sync: true);

    final stateStream = actionController.stream
        .reduxStore<S>(
          initialStateSupplier: () => initialState,
          sideEffects: [
            ...sideEffects,
            _onEachActionSideEffect(actionOutputController),
          ],
          reducer: reducer,
          logger: logger,
        )
        .handleErrorIfNeeded(errorHandler)
        .publishValueDistinct(initialState, equals: equals);

    final bag = DisposeBag(<Object>[stateStream.connect(), actionController]);

    return RxReduxStore._(
      actionController.add,
      stateStream,
      actionOutputController.stream,
      bag,
    );
  }

  /// Get stream of states.
  ///
  /// The stream skips states if they are equal to the previous state.
  /// Equality is determined by the provided [equals] method. If that is omitted,
  /// the '==' operator is used.
  ///
  /// This is useful for `StreamBuilder` in Flutter.
  ///
  /// ### Example:
  ///
  ///     StreamBuilder<LoginState>(
  ///       initialData: store.state,
  ///       stream: store.stateStream,
  ///       builder: (context, snapshot) {
  ///         final state = snapshot.data;
  ///         return LoginWidget(state); // build widget based on state.
  ///       },
  ///     );
  DistinctValueStream<S> get stateStream => _stateStream;

  /// Get streams of actions.
  ///
  /// This [Stream] includes dispatched Actions (via [dispatch] method)
  /// and Actions returned from [SideEffect]s.
  ///
  /// This is useful for triggering single events (such as display AlertDialog,
  /// SnackBar, or Navigation, ...).
  ///
  /// ### Example:
  ///
  ///     abstract class Action {}
  ///     class SubmitLogin implements Action {}
  ///     class LoginSuccess implements Action {}
  ///     class LoginFailure implements Action {}
  ///
  ///     store.actionStream
  ///       .whereType<LoginSuccess>()
  ///       .listen((_) {
  ///         showSnackBar('Login successfully');
  ///         navigateToHomeScreen();
  ///       });
  ///
  ///     store.actionStream
  ///       .whereType<LoginFailure>()
  ///       .listen((_) => showSnackBar('Login failed. Try again!'));
  Stream<A> get actionStream => _actionStream;

  /// Dispatch action to store.
  ///
  /// ### Example:
  ///
  ///     abstract class Action {}
  ///     class SubmitLogin implements Action {}
  ///
  ///     store.dispatch(SubmitLogin());
  void dispatch(A action) => _dispatch(action);

  /// Dispatch [Stream] of actions to store.
  ///
  /// The [StreamSubscription] from listening [actionStream]
  /// will be cancelled when calling [dispose].
  /// Therefore, don't forget to call [dispose] to avoid memory leaks.
  ///
  /// ### Example:
  ///
  ///     abstract class Action {}
  ///     class LoadNextPageAction implements Action {}
  ///
  ///     Stream<LoadNextPageAction> loadNextPageActionStream;
  ///     store.dispatchMany(loadNextPageActionStream);
  void dispatchMany(Stream<A> actionStream) =>
      _bag.add(actionStream.listen(_dispatch));

  /// Observe a value of type [R] exposed from a state stream, and listen only partially to changes.
  DistinctValueStream<R> select<R>(
    R Function(S) selector, {
    bool Function(R previous, R next)? equals,
  }) {
    return stateStream
        .map(selector)
        .publishValueDistinct(selector(state), equals: equals)
          ..connect().disposedBy(_bag);
  }

  /// Dispose all resources.
  /// This method is typically called in `dispose` method of Flutter `State` object.
  ///
  /// ### Example:
  ///     class LoginPageState extends State<LoginPage> {
  ///       ...
  ///       @override
  ///       void dispose() {
  ///         store.dispose();
  ///         super.dispose();
  ///       }
  ///     }
  Future<void> dispose() => _bag.dispose();
}

bool _equals<T>(T a, T b) => a == b;

/// TODO
extension SelectorsExtension<A, S> on RxReduxStore<A, S> {
  /// TODO
  DistinctValueStream<R> select2<S1, S2, R>(
    S1 Function(S) selector1,
    S2 Function(S) selector2,
    R Function(S1, S2) projector, {
    bool Function(S1 previous, S1 next)? equals1,
    bool Function(S2 previous, S2 next)? equals2,
    bool Function(R previous, R next)? equals,
  }) {
    final eq1 = equals1 ?? _equals;
    final eq2 = equals2 ?? _equals;
    final seedValue = projector(selector1(state), selector2(state));

    return stateStream
        .map((s) => Tuple2(selector1(s), selector2(s)))
        .distinct((previous, next) =>
            eq1(previous.item1, next.item1) &&
            eq2(previous.item2, previous.item2))
        .map((tuple) => projector(tuple.item1, tuple.item2))
        .publishValueDistinct(seedValue, equals: equals)
          ..connect();
  }
}

/// Get current state synchronously.
/// This is useful for filling `initialData` when using `StreamBuilder` in Flutter.
///
/// ### Example:
///
///     StreamBuilder<LoginState>(
///       initialData: store.state,
///       stream: store.stateStream,
///       builder: (context, snapshot) {
///         final state = snapshot.data;
///         return LoginWidget(state); // build widget based on state.
///       },
///     );
extension GetStateExtension<A, S> on RxReduxStore<A, S> {
  /// Get current state synchronously.
  /// This is useful for filling `initialData` when using `StreamBuilder` in Flutter.
  ///
  /// ### Example:
  ///
  ///     StreamBuilder<LoginState>(
  ///       initialData: store.state,
  ///       stream: store.stateStream,
  ///       builder: (context, snapshot) {
  ///         final state = snapshot.data;
  ///         return LoginWidget(state); // build widget based on state.
  ///       },
  ///     );
  S get state => stateStream.requireValue;
}

/// Dispatch this action to [store].
extension DispatchToExtension<A> on A {
  /// Dispatch this action to [store].
  /// See [RxReduxStore.dispatch].
  void dispatchTo<S>(RxReduxStore<A, S> store) => store.dispatch(this);
}

/// Dispatch this actions [Stream] to [store].
extension DispatchToStreamExtension<A> on Stream<A> {
  /// Dispatch this actions [Stream] to [store].
  /// See [RxReduxStore.dispatchMany].
  void dispatchTo<S>(RxReduxStore<A, S> store) => store.dispatchMany(this);
}
