/// Logger that logs message such as action, state, etc...
typedef RxReduxLogger = void Function(String message);

void _defaultLogger(String message) =>
    print('🜄 [RxRedux] - ${DateTime.now()}: $message');

/// Default [RxReduxLogger], print message to the console.
const RxReduxLogger rxReduxDefaultLogger = _defaultLogger;
