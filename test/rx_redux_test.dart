import 'package:test/test.dart';

import 'store_test.dart' as store_test;
import 'stream_transformer_test.dart' as stream_transformer_test;

void main() {
  group('rx_redux', () {
    stream_transformer_test.main();
    store_test.main();
  });
}
