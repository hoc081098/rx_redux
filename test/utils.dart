import 'package:quiver/core.dart';

/// Represents a 8-tuple.
class Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> {
  /// Returns the first item of the tuple
  final T1 item1;

  /// Returns the second item of the tuple
  final T2 item2;

  /// Returns the third item of the tuple
  final T3 item3;

  /// Returns the fourth item of the tuple
  final T4 item4;

  /// Returns the fifth item of the tuple
  final T5 item5;

  /// Returns the sixth item of the tuple
  final T6 item6;

  /// Returns the seventh item of the tuple
  final T7 item7;

  /// Returns the eighth item of the tuple
  final T8 item8;

  /// Creates a new tuple value with the specified items.
  const Tuple8(this.item1, this.item2, this.item3, this.item4, this.item5,
      this.item6, this.item7, this.item8);

  /// Returns a tuple with the first item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem1(T1 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          v, item2, item3, item4, item5, item6, item7, item8);

  /// Returns a tuple with the second item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem2(T2 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, v, item3, item4, item5, item6, item7, item8);

  /// Returns a tuple with the third item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem3(T3 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, v, item4, item5, item6, item7, item8);

  /// Returns a tuple with the fourth item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem4(T4 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, item3, v, item5, item6, item7, item8);

  /// Returns a tuple with the fifth item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem5(T5 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, item3, item4, v, item6, item7, item8);

  /// Returns a tuple with the sixth item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem6(T6 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, item3, item4, item5, v, item7, item8);

  /// Returns a tuple with the seventh item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem7(T7 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, item3, item4, item5, item6, v, item8);

  /// Returns a tuple with the eighth item set to the specified value.
  Tuple8<T1, T2, T3, T4, T5, T6, T7, T8> withItem8(T8 v) =>
      Tuple8<T1, T2, T3, T4, T5, T6, T7, T8>(
          item1, item2, item3, item4, item5, item6, item7, v);

  @override
  String toString() =>
      '[$item1, $item2, $item3, $item4, $item5, $item6, $item7, $item8]';

  @override
  bool operator ==(Object other) =>
      other is Tuple8 &&
      other.item1 == item1 &&
      other.item2 == item2 &&
      other.item3 == item3 &&
      other.item4 == item4 &&
      other.item5 == item5 &&
      other.item6 == item6 &&
      other.item7 == item7 &&
      other.item8 == item8;

  @override
  int get hashCode => hashObjects(<int>[
        item1.hashCode,
        item2.hashCode,
        item3.hashCode,
        item4.hashCode,
        item5.hashCode,
        item6.hashCode,
        item7.hashCode,
        item8.hashCode,
      ]);
}
