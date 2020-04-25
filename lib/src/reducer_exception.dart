///
class ReducerException<Action, State> implements Exception {
  ///
  final Action action;

  ///
  final State state;

  ///
  final dynamic error;

  ///
  final StackTrace stackTrace;

  ///
  ReducerException({
    this.action,
    this.state,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final message =
        "Exception was thrown by reducer, state = '$state', action = '$action'";
    return 'ReducerException: $message, error = $error, stackTrace = $stackTrace';
  }
}
