import 'dart:async';

import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';

import '../rx_redux.dart';

/// Inspirited by [NgRx memoized selector](https://ngrx.io/guide/store/selectors)
/// - Selectors can compute derived data, allowing Redux to store the minimal possible state.
/// - Selectors are efficient. A selector is not recomputed unless one of its arguments changes.
/// - When using the [select], [select2] to [select9], [selectMany] functions,
///   keeps track of the latest arguments in which your selector function was invoked.
///   Because selectors are pure functions, the last result can be returned
///   when the arguments match without reinvoking your selector function.
///   This can provide performance benefits, particularly with selectors that perform expensive computation.
///   This practice is known as memoization.
typedef Selector<State, V> = V Function(State state);

/// Select a sub state slice from state stream of [RxReduxStore].
///
/// Inspirited by [NgRx memoized selector](https://ngrx.io/guide/store/selectors)
/// - Selectors can compute derived data, allowing Redux to store the minimal possible state.
/// - Selectors are efficient. A selector is not recomputed unless one of its arguments changes.
/// - When using the [select], [select2] to [select9], [selectMany] functions,
///   keeps track of the latest arguments in which your selector function was invoked.
///   Because selectors are pure functions, the last result can be returned
///   when the arguments match without reinvoking your selector function.
///   This can provide performance benefits, particularly with selectors that perform expensive computation.
///   This practice is known as memoization.
extension SelectorsExtension<Action, State> on RxReduxStore<Action, State> {
  /// Observe a value of type [Result] exposed from a state stream, and listen only partially to changes.
  DistinctValueStream<Result> select<Result>(
    Selector<State, Result> selector, {
    Equals<Result>? equals,
  }) =>
      stateStream.map(selector).distinctValue(selector(state), equals: equals);

  /// Select two sub states and combine them by [projector].
  DistinctValueStream<Result> select2<SubState1, SubState2, Result>(
    Selector<State, SubState1> selector1,
    Selector<State, SubState2> selector2,
    Result Function(SubState1 subState1, SubState2 subState2) projector, {
    Equals<SubState1>? equals1,
    Equals<SubState2>? equals2,
    Equals<Result>? equals,
  }) =>
      _select2Internal(
        stateStream,
        selector1,
        selector2,
        projector,
        equals1,
        equals2,
        equals,
      );

  /// Select three sub states and combine them by [projector].
  DistinctValueStream<Result> select3<SubState1, SubState2, SubState3, Result>(
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
      _select3Internal(
        stateStream,
        selector1,
        selector2,
        selector3,
        projector,
        equals1,
        equals2,
        equals3,
        equals,
      );

  /// Select four sub states and combine them by [projector].
  DistinctValueStream<Result>
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
          _select4Internal(
            stateStream,
            selector1,
            selector2,
            selector3,
            selector4,
            projector,
            equals1,
            equals2,
            equals3,
            equals4,
            equals,
          );

  /// Select five sub states and combine them by [projector].
  DistinctValueStream<Result>
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
  }) {
    return selectMany<Object?, Result>(
      [
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
      ],
      [
        _castToDynamicParams<SubState1>(equals1),
        _castToDynamicParams<SubState2>(equals2),
        _castToDynamicParams<SubState3>(equals3),
        _castToDynamicParams<SubState4>(equals4),
        _castToDynamicParams<SubState5>(equals5),
      ],
      (subStates) => projector(
        subStates[0] as SubState1,
        subStates[1] as SubState2,
        subStates[2] as SubState3,
        subStates[3] as SubState4,
        subStates[4] as SubState5,
      ),
    );
  }

  /// Select five sub states and combine them by [projector].
  DistinctValueStream<Result> select6<SubState1, SubState2, SubState3,
      SubState4, SubState5, SubState6, Result>(
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
  }) {
    return selectMany<Object?, Result>(
      [
        selector1,
        selector2,
        selector3,
        selector4,
        selector5,
        selector6,
      ],
      [
        _castToDynamicParams<SubState1>(equals1),
        _castToDynamicParams<SubState2>(equals2),
        _castToDynamicParams<SubState3>(equals3),
        _castToDynamicParams<SubState4>(equals4),
        _castToDynamicParams<SubState5>(equals5),
        _castToDynamicParams<SubState6>(equals6),
      ],
      (subStates) => projector(
        subStates[0] as SubState1,
        subStates[1] as SubState2,
        subStates[2] as SubState3,
        subStates[3] as SubState4,
        subStates[4] as SubState5,
        subStates[5] as SubState6,
      ),
    );
  }

  /// Select many sub states and combine them by [projector].
  DistinctValueStream<Result> selectMany<SubState, Result>(
    List<Selector<State, SubState>> selectors,
    List<Equals<SubState>?> subStateEquals,
    Result Function(List<SubState> subStates) projector, {
    Equals<Result>? equals,
  }) {
    final length = selectors.length;
    if (length != subStateEquals.length) {
      throw ArgumentError(
          'selectors and subStateEquals should have same length');
    }

    if (length == 0) {
      throw ArgumentError('selectors and subStateEquals must be not empty');
    }
    if (length == 1) {
      throw ArgumentError(
          'selectors contains single element. Use select(selector) instead.');
    }

    selectors = selectors.toList(growable: false);
    subStateEquals = subStateEquals.toList(growable: false);

    if (length == 2) {
      return _select2Internal<State, SubState, SubState, Result>(
        stateStream,
        selectors[0],
        selectors[1],
        (subState1, subState2) => projector([subState1, subState2]),
        subStateEquals[0],
        subStateEquals[1],
        equals,
      );
    }
    if (length == 3) {
      return _select3Internal<State, SubState, SubState, SubState, Result>(
        stateStream,
        selectors[0],
        selectors[1],
        selectors[2],
        (subState1, subState2, subState3) =>
            projector([subState1, subState2, subState3]),
        subStateEquals[0],
        subStateEquals[1],
        subStateEquals[2],
        equals,
      );
    }

    final selectSubStats =
        (State state) => selectors.map((s) => s(state)).toList(growable: false);

    final eqs = subStateEquals
        .map((e) => e ?? DistinctValueStream.defaultEquals)
        .toList(growable: false);

    late final indices = Iterable<int>.generate(length);
    final subStatesEquals = (List<SubState> previous, List<SubState> next) =>
        indices.every((i) => eqs[i](previous[i], next[i]));

    return stateStream
        .map(selectSubStats)
        .distinct(subStatesEquals)
        .map(projector)
        .distinctValue(
          projector(selectSubStats(state)),
          equals: equals,
        );
  }
}

//
// Optimized for performance instead of using `selectMany`.
// _select2Internal
// _select3Internal
// _select4Internal
// from select5 to select9, using `selectMany`.

Equals<Object?>? _castToDynamicParams<T>(Equals<T>? f) {
  if (T == dynamic) {
    throw StateError('Missing generic type');
  }
  return f == null ? null : (Object? l, Object? r) => f(l as T, r as T);
}

const _sentinel = Object();

DistinctValueStream<Result>
    _select2Internal<State, SubState1, SubState2, Result>(
  DistinctValueStream<State> stateStream,
  Selector<State, SubState1> selector1,
  Selector<State, SubState2> selector2,
  Result Function(SubState1 subState1, SubState2 subState2) projector,
  Equals<SubState1>? equals1,
  Equals<SubState2>? equals2,
  Equals<Result>? equals,
) {
  final eq1 = equals1 ?? DistinctValueStream.defaultEquals;
  final eq2 = equals2 ?? DistinctValueStream.defaultEquals;

  final controller = StreamController<Result>(sync: true);

  StreamSubscription<State>? subscription;
  Object? subState1 = _sentinel;
  Object? subState2 = _sentinel;

  controller.onListen = () {
    subscription = stateStream.listen(
      (state) {
        final prev1 = subState1;
        final prev2 = subState2;

        final current1 = selector1(state);
        final current2 = selector2(state);

        if ((identical(prev1, _sentinel) && identical(prev2, _sentinel)) ||
            (!eq1(prev1 as SubState1, current1) ||
                !eq2(prev2 as SubState2, current2))) {
          subState1 = current1;
          subState2 = current2;
          controller.add(projector(current1, current2));
        }
      },
      onDone: () {
        subscription = null;
        controller.close();
      },
    );
  };
  controller.onCancel = () {
    subState1 = null;
    subState2 = null;

    final toCancel = subscription;
    subscription = null;
    return toCancel?.cancel();
  };

  final state = stateStream.value;
  return controller.stream.distinctValue(
    projector(selector1(state), selector2(state)),
    equals: equals,
  );
}

DistinctValueStream<Result>
    _select3Internal<State, SubState1, SubState2, SubState3, Result>(
  DistinctValueStream<State> stateStream,
  Selector<State, SubState1> selector1,
  Selector<State, SubState2> selector2,
  Selector<State, SubState3> selector3,
  Result Function(SubState1 subState1, SubState2 subState2, SubState3 subState3)
      projector,
  Equals<SubState1>? equals1,
  Equals<SubState2>? equals2,
  Equals<SubState3>? equals3,
  Equals<Result>? equals,
) {
  final eq1 = equals1 ?? DistinctValueStream.defaultEquals;
  final eq2 = equals2 ?? DistinctValueStream.defaultEquals;
  final eq3 = equals3 ?? DistinctValueStream.defaultEquals;

  final controller = StreamController<Result>(sync: true);

  StreamSubscription<State>? subscription;
  Object? subState1 = _sentinel;
  Object? subState2 = _sentinel;
  Object? subState3 = _sentinel;

  controller.onListen = () {
    subscription = stateStream.listen(
      (state) {
        final prev1 = subState1;
        final prev2 = subState2;
        final prev3 = subState3;

        final current1 = selector1(state);
        final current2 = selector2(state);
        final current3 = selector3(state);

        if ((identical(prev1, _sentinel) &&
                identical(prev2, _sentinel) &&
                identical(prev3, _sentinel)) ||
            (!eq1(prev1 as SubState1, current1) ||
                !eq2(prev2 as SubState2, current2) ||
                !eq3(prev3 as SubState3, current3))) {
          subState1 = current1;
          subState2 = current2;
          subState3 = current3;
          controller.add(projector(current1, current2, current3));
        }
      },
      onDone: () {
        subscription = null;
        controller.close();
      },
    );
  };
  controller.onCancel = () {
    subState1 = null;
    subState2 = null;
    subState3 = null;

    final toCancel = subscription;
    subscription = null;
    return toCancel?.cancel();
  };

  final state = stateStream.value;
  return controller.stream.distinctValue(
    projector(selector1(state), selector2(state), selector3(state)),
    equals: equals,
  );
}

DistinctValueStream<Result>
    _select4Internal<State, SubState1, SubState2, SubState3, SubState4, Result>(
  DistinctValueStream<State> stateStream,
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
      projector,
  Equals<SubState1>? equals1,
  Equals<SubState2>? equals2,
  Equals<SubState3>? equals3,
  Equals<SubState4>? equals4,
  Equals<Result>? equals,
) {
  final eq1 = equals1 ?? DistinctValueStream.defaultEquals;
  final eq2 = equals2 ?? DistinctValueStream.defaultEquals;
  final eq3 = equals3 ?? DistinctValueStream.defaultEquals;
  final eq4 = equals4 ?? DistinctValueStream.defaultEquals;

  final controller = StreamController<Result>(sync: true);

  StreamSubscription<State>? subscription;
  Object? subState1 = _sentinel;
  Object? subState2 = _sentinel;
  Object? subState3 = _sentinel;
  Object? subState4 = _sentinel;

  controller.onListen = () {
    subscription = stateStream.listen(
      (state) {
        final prev1 = subState1;
        final prev2 = subState2;
        final prev3 = subState3;
        final prev4 = subState4;

        final current1 = selector1(state);
        final current2 = selector2(state);
        final current3 = selector3(state);
        final current4 = selector4(state);

        if ((identical(prev1, _sentinel) &&
                identical(prev2, _sentinel) &&
                identical(prev3, _sentinel) &&
                identical(prev4, _sentinel)) ||
            (!eq1(prev1 as SubState1, current1) ||
                !eq2(prev2 as SubState2, current2) ||
                !eq3(prev3 as SubState3, current3) ||
                !eq4(prev4 as SubState4, current4))) {
          subState1 = current1;
          subState2 = current2;
          subState3 = current3;
          subState4 = current4;
          controller.add(projector(current1, current2, current3, current4));
        }
      },
      onDone: () {
        subscription = null;
        controller.close();
      },
    );
  };
  controller.onCancel = () {
    subState1 = null;
    subState2 = null;
    subState3 = null;
    subState4 = null;

    final toCancel = subscription;
    subscription = null;
    return toCancel?.cancel();
  };

  final state = stateStream.value;
  return controller.stream.distinctValue(
    projector(
      selector1(state),
      selector2(state),
      selector3(state),
      selector4(state),
    ),
    equals: equals,
  );
}
