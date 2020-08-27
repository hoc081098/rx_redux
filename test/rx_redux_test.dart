import 'package:rx_redux/rx_redux.dart';
import 'package:test/test.dart';

import 'store_test.dart' as store_test;
import 'stream_transformer_test.dart' as stream_transformer_test;

void main() {
  group('rx_redux', () {
    stream_transformer_test.main();
    store_test.main();

    group('ReducerException', () {
      test('constructor', () {
        try {
          throw StateError('FakeError');
        } catch (e, st) {
          final matcher = const TypeMatcher<ReducerException<int, String>>()
              .having(
                (e) => e.action,
                'ReducerException.action',
                const TypeMatcher<int>().having((a) => a, 'Action', 0),
              )
              .having(
                (e) => e.state,
                'ReducerException.state',
                const TypeMatcher<String>().having(
                  (s) => s,
                  'Current state',
                  'InitialState',
                ),
              )
              .having(
                (e) => e.error,
                'ReducerException.error',
                const TypeMatcher<StateError>().having(
                  (s) => s.message,
                  'Caused error message',
                  'FakeError',
                ),
              )
              .having((e) => e.stackTrace, 'ReducerException.stackTrace', st);

          expect(
            ReducerException<int, String>(
              action: 0,
              state: 'InitialState',
              error: e,
              stackTrace: st,
            ),
            matcher,
          );
        }
      });

      test('toString', () {
        try {
          throw Exception();
        } catch (e, st) {
          final s = ReducerException<int, String>(
            action: 1,
            state: '2',
            error: e,
            stackTrace: st,
          ).toString();

          expect(s,
              'ReducerException: ${"Exception was thrown by reducer, state = '2', action = '1'"}, error = $e, stackTrace = $st');
        }
      });

      test('hashCode', () {
        try {
          throw Exception();
        } catch (e, st) {
          expect(
            ReducerException<int, String>(
              action: 1,
              state: '2',
              error: e,
              stackTrace: st,
            ).hashCode,
            ReducerException<int, String>(
              action: 1,
              state: '2',
              error: e,
              stackTrace: st,
            ).hashCode,
          );
        }
      });

      test('operator ==', () {
        try {
          throw Exception();
        } catch (e, st) {
          expect(
            ReducerException<int, String>(
                  action: 1,
                  state: '2',
                  error: e,
                  stackTrace: st,
                ) ==
                ReducerException<int, String>(
                  action: 1,
                  state: '2',
                  error: e,
                  stackTrace: st,
                ),
            isTrue,
          );
        }
      });
    });
  });
}
