import 'package:rxdart_ext/state_stream.dart';

import 'store.dart';

/// Select a sub state slice from state stream of [RxReduxStore].
///
/// Inspirited by [NgRx memoized selector](https://ngrx.io/guide/store/selectors)
/// - Selectors can compute derived data, allowing Redux to store the minimal possible state.
/// - Selectors are efficient. A selector is not recomputed unless one of its arguments changes.
/// - When using the [select], [select2] to [select9], [selectMany] functions,
///   keeps track of the latest arguments in which your selector function was invoked.
///   Because selectors are pure functions, the last result can be returned
///   when the arguments match without re-invoking your selector function.
///   This can provide performance benefits, particularly with selectors that perform expensive computation.
///   This practice is known as memoization.
extension SelectorsExtension<Action, State> on RxReduxStore<Action, State> {
  /// Observe a value of type [Result] exposed from a state stream, and listen only partially to changes.
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select<Result>(
    Selector<State, Result> selector, {
    Equals<Result>? equals,
  }) =>
      stateStream.select(selector, equals: equals);

  /// Select two sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select2<SubState1, SubState2, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Result Function(SubState1 subState1, SubState2 subState2) projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<Result>? equals,
  }) =>
      stateStream.select2(
        selector1,
        selector2,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals: equals,
      );

  /// Select three sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select3<SubState1, SubState2, SubState3, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Result Function(
            SubState1 subState1, SubState2 subState2, SubState3 subState3)
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<Result>? equals,
  }) =>
      stateStream.select3(
        selector1,
        selector2,
        selector3,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals3: equals3,
        equals: equals,
      );

  /// Select four sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result>
      select4<SubState1, SubState2, SubState3, SubState4, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<Result>? equals,
  }) =>
          stateStream.select4(
            selector1,
            selector2,
            selector3,
            selector4,
            projector,
            equals1: equals1,
            equals2: equals2,
            equals3: equals3,
            equals4: equals4,
            equals: equals,
          );

  /// Select five sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result>
      select5<SubState1, SubState2, SubState3, SubState4, SubState5, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Selector<State, SubState5> selector5,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
      SubState5 subState5,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<SubState5>? equals5,
    Equals<Result>? equals,
  }) =>
          stateStream.select5(
            selector1,
            selector2,
            selector3,
            selector4,
            selector5,
            projector,
            equals1: equals1,
            equals2: equals2,
            equals3: equals3,
            equals4: equals4,
            equals5: equals5,
            equals: equals,
          );

  /// Select five sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select6<SubState1, SubState2, SubState3, SubState4,
          SubState5, SubState6, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Selector<State, SubState5> selector5,
    Selector<State, SubState6> selector6,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
      SubState5 subState5,
      SubState6 subState6,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<SubState5>? equals5,
    Equals<SubState6>? equals6,
    Equals<Result>? equals,
  }) =>
      stateStream.select6(
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
        selector6,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals3: equals3,
        equals4: equals4,
        equals5: equals5,
        equals6: equals6,
        equals: equals,
      );

  /// Select seven sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select7<SubState1, SubState2, SubState3, SubState4,
          SubState5, SubState6, SubState7, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Selector<State, SubState5> selector5,
    Selector<State, SubState6> selector6,
    Selector<State, SubState7> selector7,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
      SubState5 subState5,
      SubState6 subState6,
      SubState7 subState7,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<SubState5>? equals5,
    Equals<SubState6>? equals6,
    Equals<SubState7>? equals7,
    Equals<Result>? equals,
  }) =>
      stateStream.select7(
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
        selector6,
        selector7,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals3: equals3,
        equals4: equals4,
        equals5: equals5,
        equals6: equals6,
        equals7: equals7,
        equals: equals,
      );

  /// Select eight sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select8<SubState1, SubState2, SubState3, SubState4,
          SubState5, SubState6, SubState7, SubState8, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Selector<State, SubState5> selector5,
    Selector<State, SubState6> selector6,
    Selector<State, SubState7> selector7,
    Selector<State, SubState8> selector8,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
      SubState5 subState5,
      SubState6 subState6,
      SubState7 subState7,
      SubState8 subState8,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<SubState5>? equals5,
    Equals<SubState6>? equals6,
    Equals<SubState7>? equals7,
    Equals<SubState8>? equals8,
    Equals<Result>? equals,
  }) =>
      stateStream.select8(
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
        selector6,
        selector7,
        selector8,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals3: equals3,
        equals4: equals4,
        equals5: equals5,
        equals6: equals6,
        equals7: equals7,
        equals8: equals8,
        equals: equals,
      );

  /// Select nine sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> select9<SubState1, SubState2, SubState3, SubState4,
          SubState5, SubState6, SubState7, SubState8, SubState9, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Selector<State, SubState3> selector3,
    Selector<State, SubState4> selector4,
    Selector<State, SubState5> selector5,
    Selector<State, SubState6> selector6,
    Selector<State, SubState7> selector7,
    Selector<State, SubState8> selector8,
    Selector<State, SubState9> selector9,
    Result Function(
      SubState1 subState1,
      SubState2 subState2,
      SubState3 subState3,
      SubState4 subState4,
      SubState5 subState5,
      SubState6 subState6,
      SubState7 subState7,
      SubState8 subState8,
      SubState9 subState9,
    )
        projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<SubState3>? equals3,
    Equals<SubState4>? equals4,
    Equals<SubState5>? equals5,
    Equals<SubState6>? equals6,
    Equals<SubState7>? equals7,
    Equals<SubState8>? equals8,
    Equals<SubState9>? equals9,
    Equals<Result>? equals,
  }) =>
      stateStream.select9(
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
        selector6,
        selector7,
        selector8,
        selector9,
        projector,
        equals1: equals1,
        equals2: equals2,
        equals3: equals3,
        equals4: equals4,
        equals5: equals5,
        equals6: equals6,
        equals7: equals7,
        equals8: equals8,
        equals9: equals9,
        equals: equals,
      );

  /// Select many sub states and combine them by [projector].
  ///
  /// The returned Stream is a single-subscription Stream.
  StateStream<Result> selectMany<SubState, Result>(
    List<Selector<State, SubState>> selectors,
    List<Equals<SubState>?> subStateEquals,
    Result Function(List<SubState> subStates) projector, {
    Equals<Result>? equals,
  }) =>
      stateStream.selectMany(
        selectors,
        subStateEquals,
        projector,
        equals: equals,
      );
}
