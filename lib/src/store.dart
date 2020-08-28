import 'dart:async';

import 'package:meta/meta.dart';

import 'logger.dart';
import 'reducer.dart';
import 'redux_store_stream_transformer.dart';
import 'side_effect.dart';

/// A [SideEffect] that returns a never-completed Stream and on each action received,
/// adding it to [outputSink].
SideEffect<A, S> _onEachActionSideEffect<A, S>(StreamSink<A> outputSink) {
  return (actions, _) {
    final neverController = StreamController<A>();
    StreamSubscription<A> subscription;

    neverController.onListen =
        () => subscription = actions.listen(outputSink.add);
    neverController.onCancel = () async {
      await subscription.cancel();
      await outputSink.close();
    };

    return neverController.stream;
  };
}

/// Rx Redux Store.
/// Redux store based on [Stream].
class RxReduxStore<A, S> {
  final void Function(A) _dispatch;

  final GetState<S> _getState;
  final Stream<S> _stateStream;
  final Stream<A> _actionStream;

  final Future<void> Function() _dispose;

  const RxReduxStore._(
    this._dispatch,
    this._getState,
    this._stateStream,
    this._actionStream,
    this._dispose,
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
  factory RxReduxStore({
    @required S initialState,
    @required List<SideEffect<A, S>> sideEffects,
    @required Reducer<A, S> reducer,
    void Function(Object, StackTrace) errorHandler,
    bool Function(S previous, S next) equals,
    RxReduxLogger logger,
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
        .distinct(equals)
        .skip(1)
        .asBroadcastStream(onCancel: (subscription) => subscription.cancel());

    var currentState = initialState;
    final subscription = stateStream.listen(
      (newState) => currentState = newState,
      onError: errorHandler,
    );

    return RxReduxStore._(
      actionController.add,
      () => currentState,
      stateStream,
      actionOutputController.stream,
      () async {
        await actionController.close();
        await subscription.cancel();
      },
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
  Stream<S> get stateStream => _stateStream;

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
  S get state => _getState();

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
  Future<void> dispose() => _dispose();
}
