import 'dart:async';

import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';

import '../rx_redux.dart';

bool Function(Object?, Object?)? _castToDynamicParams<T>(
    bool Function(T previous, T next)? f) {
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
    bool Function(Result previous, Result next)? equals,
  }) =>
      stateStream.map(selector).distinctValue(selector(state), equals: equals);

  /// Select two sub state and combine them by [projector].
  DistinctValueStream<Result> select2<SubState1, SubState2, Result>(
    SubState1 Function(State state) selector1,
    SubState2 Function(State state) selector2,
    Result Function(SubState1 subState1, SubState2 subState2) projector, {
    bool Function(SubState1 previous, SubState1 next)? equals1,
    bool Function(SubState2 previous, SubState2 next)? equals2,
    bool Function(Result previous, Result next)? equals,
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

  /// TODO
  DistinctValueStream<R> select3<S1, S2, S3, R>(
    S1 Function(State state) selector1,
    S2 Function(State state) selector2,
    S3 Function(State state) selector3,
    R Function(S1 subState1, S2 subState2, S3 subState3) projector, {
    bool Function(S1 previous, S1 next)? equals1,
    bool Function(S2 previous, S2 next)? equals2,
    bool Function(S3 previous, S3 next)? equals3,
    bool Function(R previous, R next)? equals,
  }) {
    return selectMany<R, Object?>(
      [selector1, selector2, selector3],
      [
        _castToDynamicParams<S1>(equals1),
        _castToDynamicParams<S2>(equals2),
        _castToDynamicParams<S3>(equals3),
      ],
      (subStates) => projector(
        subStates[0] as S1,
        subStates[1] as S2,
        subStates[2] as S3,
      ),
      equals: equals,
    );
  }

  /// TODO
  DistinctValueStream<Result> selectMany<Result, SubState>(
    List<SubState Function(State state)> selectors,
    List<bool Function(SubState previous, SubState next)?> subStateEquals,
    Result Function(List<SubState> subStates) projector, {
    bool Function(Result previous, Result next)? equals,
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

const _sentinel = Object();

DistinctValueStream<Result>
    _select2Internal<State, SubState1, SubState2, Result>(
  DistinctValueStream<State> stateStream,
  SubState1 Function(State state) selector1,
  SubState2 Function(State state) selector2,
  Result Function(SubState1 subState1, SubState2 subState2) projector,
  bool Function(SubState1 previous, SubState1 next)? equals1,
  bool Function(SubState2 previous, SubState2 next)? equals2,
  bool Function(Result previous, Result next)? equals,
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
