import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';

import '../rx_redux.dart';

bool _equals<T>(T a, T b) => a == b;

bool Function(Object?, Object?)? _castToDynamicParams<T>(
    bool Function(T previous, T next)? f) {
  if (T == dynamic) {
    throw StateError('Missing generic type');
  }
  return f == null ? null : (Object? l, Object? r) => f(l as T, r as T);
}

/// TODO
extension SelectorsExtension<A, S> on RxReduxStore<A, S> {
  /// Observe a value of type [R] exposed from a state stream, and listen only partially to changes.
  DistinctValueStream<R> select<R>(
    R Function(S) selector, {
    bool Function(R previous, R next)? equals,
  }) =>
      stateStream
          .map(selector)
          .shareValueDistinct(selector(state), equals: equals);

  /// TODO
  DistinctValueStream<R> select2<S1, S2, R>(
    S1 Function(S) selector1,
    S2 Function(S) selector2,
    R Function(S1, S2) projector, {
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
    S1 Function(S) selector1,
    S2 Function(S) selector2,
    S3 Function(S) selector3,
    R Function(S1, S2, S3) projector, {
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
    List<SubState Function(S)> selectors,
    List<bool Function(SubState previous, SubState next)?> subStateEquals,
    Result Function(List<SubState>) projector, {
    bool Function(Result previous, Result next)? equals,
  }) {
    if (selectors.length != subStateEquals.length) {
      throw StateError('selectors and subStateEquals should have same length');
    }

    final selectSubStats =
        (S state) => selectors.map((s) => s(state)).toList(growable: false);

    final eqs = subStateEquals.map((e) => e ?? _equals).toList(growable: false);

    final subStatesEquals = (List<SubState> previous, List<SubState> next) {
      if (previous.length != next.length) {
        throw StateError('selectors should be a fixed-length List');
      }
      return Iterable<int>.generate(previous.length).every((i) {
        final eq = eqs[i];
        return eq(previous[i], next[i]);
      });
    };

    return stateStream
        .map(selectSubStats)
        .distinct(subStatesEquals)
        .map(projector)
        .shareValueDistinct(
          projector(selectSubStats(state)),
          equals: equals,
        );
  }
}
