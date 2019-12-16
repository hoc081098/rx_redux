///
/// It is a function which takes a stream of actions and returns a stream of actions.
/// Actions in, actions out (concept borrowed from redux-observable.js.or - so called epics).
///
/// * Param [actions] [Observable<A>] input action. Every [SideEffect] should be responsible
/// to handle a single Action (i.e using where or ofType operator)
/// * Param [state] [StateAccessor<S>] to get the latest state of the state machine
///
typedef SideEffect<S, A> = Stream<A> Function(
  Stream<A> actions,
  StateAccessor<S> state,
);

///
/// The [StateAccessor] is basically just a deferred way to get a state
/// of a ReduxStore stream at any given point in time.
/// So you have to call this method to get the state.
///
typedef StateAccessor<S> = S Function();
