// ignore_for_file: public_member_api_docs

extension MapIndexedIterableExtensison<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) sync* {
    var index = 0;
    for (final t in this) {
      yield mapper(index++, t);
    }
  }
}
