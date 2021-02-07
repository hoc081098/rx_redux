import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';

import 'logger.dart';
import 'reducer.dart';
import 'redux_store_stream_transformer.dart';
import 'side_effect.dart';

/// Determine equality.
typedef Equals<T> = bool Function(T previous, T next);

/// Handle an error and the corresponding stack trace.
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

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
  Stream<S> handleErrorIfNeeded(ErrorHandler? errorHandler) =>
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
    ErrorHandler? errorHandler,
    Equals<S>? equals,
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
