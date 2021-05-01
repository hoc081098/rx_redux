// ignore_for_file: public_member_api_docs

extension MapIndexedIterableExtensison<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) sync* {
    var index = 0;
    for (final t in this) {
      yield mapper(index++, t);
    }
  }
}

/// Returns a 5 character long hexadecimal string generated from
/// [Object.hashCode]'s 20 least-significant bits.
String shortHash(Object? object) =>
    object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
