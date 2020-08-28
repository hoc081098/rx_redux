// ignore_for_file: public_member_api_docs

extension MapIndexedIterableExtensison<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) {
    var index = 0;
    return map((t) => mapper(index++, t));
  }
}
