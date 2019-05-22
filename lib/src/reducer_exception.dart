class ReducerException implements Exception {
  final action;
  final state;
  final cause;

  const ReducerException(this.action, this.state, this.cause);

  @override
  String toString() {
    final message =
        "Exception was thrown by reducer, state = '$state', action = '$action'";
    return 'ReducerException{message: $message, action: $action, state: $state, cause: $cause}';
  }
}
