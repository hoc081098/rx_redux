import 'dart:async';

import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';

import '../rx_redux.dart';

Equals<Object?>? _castToDynamicParams<T>(Equals<T>? f) {
  if (T == dynamic) {
    throw StateError('Missing generic type');
  }
  return f == null ? null : (Object? l, Object? r) => f(l as T, r as T);
}

/// Select a sub state slice from state stream of [RxReduxStore].
extension SelectorsExtension<Action, State> on RxReduxStore<Action, State> {
  /// Observe a value of type [Result] exposed from a state stream, and listen only partially to changes.
  DistinctValueStream<Result> select<Result>(
    Result Function(State state) selector, {
    Equals<Result>? equals,
  }) =>
      stateStream.map(selector).distinctValue(selector(state), equals: equals);

  /// Select two sub states and combine them by [projector].
  DistinctValueStream<Result> select2<SubState1, SubState2, Result>(
    SubState1 Function(State state) selector1,
    SubState2 Function(State state) selector2,
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
    SubState1 Function(State state) selector1,
    SubState2 Function(State state) selector2,
    SubState3 Function(State state) selector3,
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

  /// TODO
  DistinctValueStream<Result> selectMany<Result, SubState>(
    List<SubState Function(State state)> selectors,
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
      final selector = selectors.first;
      final subStateEqual = subStateEquals.first;

      return stateStream
          .map((s) => selector(s))
          .distinct(subStateEqual)
          .map((s) => projector([s]))
          .distinctValue(projector([selector(state)]), equals: equals);
    }
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

    selectors = selectors.toList(growable: false);
    subStateEquals = subStateEquals.toList(growable: false);

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

const _sentinel = Object();

DistinctValueStream<Result>
    _select2Internal<State, SubState1, SubState2, Result>(
  DistinctValueStream<State> stateStream,
  SubState1 Function(State state) selector1,
  SubState2 Function(State state) selector2,
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
  SubState1 Function(State state) selector1,
  SubState2 Function(State state) selector2,
  SubState3 Function(State state) selector3,
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
