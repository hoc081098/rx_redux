class ReducerException implements Exception {
  final action;
  final state;
  final error;
  final StackTrace stackTrace;

  const ReducerException({
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
