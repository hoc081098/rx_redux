import 'package:meta/meta.dart';

/// Exception thrown by reducer
class ReducerException<A, S> implements Exception {
  /// Action passed into reducer
  final A action;

  /// Current state passed into reducer
  final S state;

  /// Error thrown
  final Object error;

  /// Stacktrace
  final StackTrace stackTrace;

  /// Construct a [ReducerException]
  const ReducerException({
    @required this.action,
    @required this.state,
    @required this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final message =
        "Exception was thrown by reducer, state = '$state', action = '$action'";
    return 'ReducerException: $message, error = $error, stackTrace = $stackTrace';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReducerException &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          state == other.state &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode =>
      action.hashCode ^ state.hashCode ^ error.hashCode ^ stackTrace.hashCode;
}
