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
extension SelectorsExtension<A, S> on RxReduxStore<A, S> {
  /// Observe a value of type [R] exposed from a state stream, and listen only partially to changes.
  DistinctValueStream<R> select<R>(
    R Function(S state) selector, {
    bool Function(R previous, R next)? equals,
  }) =>
      stateStream.map(selector).distinctValue(selector(state), equals: equals);

  /// Select two sub state and combine them by [projector].
  DistinctValueStream<R> select2<S1, S2, R>(
    S1 Function(S state) selector1,
    S2 Function(S state) selector2,
    R Function(S1 subState1, S2 subState2) projector, {
    bool Function(S1 previous, S1 next)? equals1,
    bool Function(S2 previous, S2 next)? equals2,
    bool Function(R previous, R next)? equals,
  }) {
    return selectMany<R, Object?>(
      [selector1, selector2],
      [
        _castToDynamicParams<S1>(equals1),
        _castToDynamicParams<S2>(equals2),
      ],
      (subStates) => projector(subStates[0] as S1, subStates[1] as S2),
      equals: equals,
    );
  }

  /// TODO
  DistinctValueStream<R> select3<S1, S2, S3, R>(
    S1 Function(S state) selector1,
    S2 Function(S state) selector2,
    S3 Function(S state) selector3,
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
    List<SubState Function(S state)> selectors,
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
      throw ArgumentError('selectors must be not empty');
    }
    if (length == 1) {
      throw ArgumentError(
          'selectors contains single element. Use select(selector) instead.');
    }

    selectors = selectors.toList(growable: false);
    subStateEquals = subStateEquals.toList(growable: false);

    final selectSubStats =
        (S state) => selectors.map((s) => s(state)).toList(growable: false);

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
