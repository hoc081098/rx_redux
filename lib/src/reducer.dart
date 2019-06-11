///
/// A simple type alias for a reducer function.
/// A [Reducer] takes a State and an Action as input and produces a state as output.
///
/// If a reducer should not react on a Action, just return the old State.
///
/// * Param [currentState] [S] The type of the state
/// * Param [newAction] [A] The type of the Actions
///

typedef S Reducer<S, A>(S currentState, A newAction);
