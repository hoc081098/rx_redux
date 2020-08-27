///
/// It is a function which takes a stream of actions and returns a stream of actions.
/// Actions in, actions out (concept borrowed from redux-observable.js.or - so called epics).
///
/// * Param [actions]: [Stream<A>] input action. Every [SideEffect] should be responsible
/// to handle a single Action (i.e using where or whereType operator from rxdart package)
/// * Param [state]: [GetState<S>] to get the latest state of the state machine
///
typedef SideEffect<A, S> = Stream<A> Function(
  Stream<A> actions,
  GetState<S> getState,
);

///
/// The [GetState] is basically just a deferred way to get a state
/// of a ReduxStore stream at any given point in time.
/// So you have to call this method to get the state.
///
typedef GetState<S> = S Function();
