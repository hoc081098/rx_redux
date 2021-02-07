import 'package:built_collection/built_collection.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

enum Action {
  action1,
  action2,
  action3,
  actionSideEffect1,
  actionSideEffect2,
  actionSideEffect3,
  actionNoOp
}

Future<void> delay(int millis) =>
    Future.delayed(Duration(milliseconds: millis));

void main() {
  group('RxReduxStore', () {
    test('Get initialState', () {
      final store = RxReduxStore<Action, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s,
      );
      expect(store.state, 0);
    });

    test('Get current state', () async {
      final store = RxReduxStore<int, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s + a,
      );
      expect(store.state, 0);

      store.dispatch(1);
      await delay(100);
      expect(store.state, 1);

      store.dispatch(10);
      await delay(100);
      expect(store.state, 11);

      store.dispatch(-11);
      await delay(100);
      expect(store.state, 0);
    });

    test('Get state stream that never emits', () {
      final store = RxReduxStore<int, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s + a,
      );

      store.stateStream.listen((event) => expect(true, isFalse));
      Future<void>.delayed(const Duration(seconds: 1));
    });

    test('Get state stream', () async {
      final store = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => '$s+$a',
      );

      final future = expectLater(
        store.stateStream,
        emitsInOrder(
          <String>[
            '0+1',
            '0+1+2',
            '0+1+2+3',
          ],
        ),
      );

      await delay(100);

      store.dispatch(1);
      store.dispatch(2);
      store.dispatch(3);

      await future;
      store.stateStream.listen((_) => expect(true, isFalse));
      await Future<void>.delayed(const Duration(seconds: 1));
    });

    test('Get state stream with SideEffects', () async {
      final store = RxReduxStore<Action, int>(
        initialState: 0,
        sideEffects: [
          (action, getState) => action
              .where((event) => event == Action.action1)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 100),
                  (_) => Action.actionSideEffect1).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action2)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 200),
                  (_) => Action.actionSideEffect2).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action3)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 300),
                  (_) => Action.actionSideEffect3).take(1)),
        ],
        reducer: (state, action) {
          switch (action) {
            case Action.actionSideEffect1:
              return state + 1;
            case Action.actionSideEffect2:
              return state + 2;
            case Action.actionSideEffect3:
              return state + 3;
            default:
              return state;
          }
        },
      );

      expect(
        store.stateStream,
        emitsInOrder(
          <int>[
            1,
            3,
            6,
            7,
            9,
            12,
          ],
        ),
      );
      expect(store.state, 0);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(store.state, 6);
      expect(
        store.stateStream,
        emitsInOrder(
          <int>[
            7,
            9,
            12,
          ],
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future<void>.delayed(const Duration(seconds: 1));

      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('Get action stream', () async {
      final store = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => '$s+$a',
      );

      expect(
        store.actionStream,
        emitsInOrder(<int>[1, 2, 3]),
      );

      await delay(100);

      store.dispatch(1);
      store.dispatch(2);
      store.dispatch(3);
    });

    test('Get action stream with SideEffects', () async {
      final store = RxReduxStore<Action, int>(
        initialState: 0,
        sideEffects: [
          (action, getState) => action
              .where((event) => event == Action.action1)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 100),
                  (_) => Action.actionSideEffect1).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action2)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 200),
                  (_) => Action.actionSideEffect2).take(1)),
          (action, getState) => action
              .where((event) => event == Action.action3)
              .asyncExpand((event) => Stream.periodic(
                  const Duration(milliseconds: 300),
                  (_) => Action.actionSideEffect3).take(1)),
        ],
        reducer: (state, action) {
          switch (action) {
            case Action.actionSideEffect1:
              return state + 1;
            case Action.actionSideEffect2:
              return state + 2;
            case Action.actionSideEffect3:
              return state + 3;
            default:
              return state;
          }
        },
      );

      expect(
        store.actionStream,
        emitsInOrder(
          <Action>[
            Action.action1,
            Action.action2,
            Action.action3,
            Action.actionSideEffect1,
            Action.actionSideEffect2,
            Action.actionSideEffect3,
            Action.action1,
            Action.action2,
            Action.action3,
            Action.actionSideEffect1,
            Action.actionSideEffect2,
            Action.actionSideEffect3,
            Action.actionNoOp,
            Action.actionNoOp,
            Action.actionNoOp,
          ],
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(
        store.actionStream,
        emitsInOrder(
          <Action>[
            Action.action1,
            Action.action2,
            Action.action3,
            Action.actionSideEffect1,
            Action.actionSideEffect2,
            Action.actionSideEffect3,
            Action.actionNoOp,
            Action.actionNoOp,
            Action.actionNoOp,
          ],
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.dispatch(Action.action1);
      store.dispatch(Action.action2);
      store.dispatch(Action.action3);
      await Future<void>.delayed(const Duration(seconds: 1));

      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      store.dispatch(Action.actionNoOp);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('Dispose', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => s,
      );

      await rxReduxStore.dispose();

      expect(rxReduxStore.state, '0');
      expect(() => rxReduxStore.dispatch(0), throwsStateError);
      expect(rxReduxStore.actionStream, emitsDone);
      expect(rxReduxStore.stateStream, emitsDone);
    });

    test('Error handler called when reducer throws', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [],
        reducer: (s, a) => throw Exception(),
        errorHandler: (e, s) => expect(e, isException),
      );

      rxReduxStore.dispatch(1);
    });

    test('Error handler called when SideEffect throws', () async {
      final rxReduxStore = RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [(actions, getState) => throw Exception()],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      );

      rxReduxStore.dispatch(1);
    });

    test('Error handler called when SideEffect returns error Stream', () async {
      RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [(actions, getState) => Stream.error(Exception())],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      ).dispatch(1);

      RxReduxStore<int, String>(
        initialState: '0',
        sideEffects: [
          (actions, getState) => actions
              .where((event) => event == 2)
              .asyncExpand((_) => Stream<int>.error(Exception()))
        ],
        reducer: (s, a) => s,
        errorHandler: (e, s) => expect(e, isException),
      )
        ..dispatch(1)
        ..dispatch(2);
    });

    test('Dispatch many', () async {
      {
        final store = RxReduxStore<int, int>(
          initialState: 0,
          sideEffects: [],
          reducer: (s, a) => s + a,
        );

        store.dispatchMany(Rx.range(0, 100));
        await delay(200);

        expect(store.state, 100 * 101 ~/ 2);
        await store.dispose();
      }

      {
        final store = RxReduxStore<int, int>(
          initialState: 0,
          sideEffects: [],
          reducer: (s, a) => s + a,
        );

        Rx.range(0, 100).dispatchTo(store);
        await delay(200);

        expect(store.state, 100 * 101 ~/ 2);
        await store.dispose();
      }
    });

    test('Action.dispatchTo extension method', () async {
      final store = RxReduxStore<int, int>(
        initialState: 0,
        sideEffects: [],
        reducer: (s, a) => s + a,
      );

      1.dispatchTo(store);
      2.dispatchTo(store);
      await delay(100);

      expect(store.state, 3);
      await store.dispose();
    });

    test('Nullable action', () async {
      final store = RxReduxStore<int?, String>(
        initialState: '0',
        sideEffects: [(actions, getState) => Stream.empty()],
        reducer: (s, a) => s + a.toString(),
      );

      // ignore: unnecessary_cast
      (1 as int?).dispatchTo(store);
      store.dispatch(2);
      await delay(100);
      expect(store.state, '012');

      store.dispatch(null);
      // ignore: unnecessary_cast
      (null as int?).dispatchTo(store);
      await delay(100);
      expect(store.state, '012nullnull');

      await store.dispose();
    });

    test('Nullable state', () async {
      final store = RxReduxStore<int, String?>(
        initialState: null,
        sideEffects: [(actions, getState) => Stream.empty()],
        reducer: (s, a) => a == 1 ? '1' : null,
      );

      expect(store.state, null);

      1.dispatchTo(store);
      await delay(100);
      expect(store.state, '1');

      2.dispatchTo(store);
      await delay(100);
      expect(store.state, null);

      await store.dispose();
    });

    group('selector', () {
      test('select2', () async {
        final store = RxReduxStore<int, _State>(
          initialState: _State(true, null, <String>[].build(), 1),
          sideEffects: [],
          reducer: (s, a) {
            // items [*]
            if (a == 0) {
              return _State(
                s.isLoading,
                s.term,
                List.generate(10, (i) => i.toString()).build(),
                s.otherState,
              );
            }

            // loading
            if (a == 1) {
              return _State(!s.isLoading, s.term, s.items, s.otherState);
            }

            // loading
            if (a == 2) {
              return _State(!s.isLoading, s.term, s.items, s.otherState);
            }

            // term [*]
            if (a == 3) {
              return _State(s.isLoading, '4', s.items, s.otherState);
            }

            // otherState
            if (a == 4) {
              return _State(s.isLoading, s.term, s.items, s.otherState + 2);
            }

            // loading & otherState
            if (a == 5) {
              return _State(!s.isLoading, s.term, s.items, -s.otherState);
            }

            throw a;
          },
        );

        await pumpEventQueue(times: 50);

        var termCount = 0;
        var itemsCount = 0;
        var projectorCount = 0;

        final filtered = store.select2(
          (s) {
            ++termCount;
            return s.term;
          },
          (s) {
            ++itemsCount;
            return s.items;
          },
          (String? term, BuiltList<String> items) {
            ++projectorCount;
            return items.where((i) => i.contains(term ?? '')).toBuiltList();
          },
        );

        expect(filtered.requireValue, <String>[].build());
        final future = expectLater(
          filtered,
          emitsInOrder(<Object>[
            List.generate(10, (i) => i.toString()).build(),
            ['4'].build(),
          ]),
        );

        final numberOfActions = 6;
        for (var i = 0; i < numberOfActions; i++) {
          store.dispatch(i);
        }
        await pumpEventQueue(times: 50);
        await future;

        expect(termCount,
            numberOfActions + 1); // inc. calling to produce seed value
        expect(itemsCount,
            numberOfActions + 1); // inc. calling to produce seed value
        expect(projectorCount,
            2 + 1); // 2 [*] and inc. calling to produce seed value
      });

      test('select3', () async {
        final store = RxReduxStore<int, _State>(
          initialState: _State(true, null, <String>[].build(), 2),
          sideEffects: [],
          reducer: (s, a) {
            // items [*]
            if (a == 0) {
              return _State(
                s.isLoading,
                s.term,
                List.generate(10, (i) => i.toString()).build(),
                s.otherState,
              );
            }

            // loading
            if (a == 1) {
              return _State(!s.isLoading, s.term, s.items, s.otherState);
            }

            // loading
            if (a == 2) {
              return _State(!s.isLoading, s.term, s.items, s.otherState);
            }

            // term [*]
            if (a == 3) {
              return _State(s.isLoading, '4', s.items, s.otherState);
            }

            // otherState [*]
            if (a == 4) {
              return _State(s.isLoading, s.term, s.items, s.otherState + 2);
            }

            // loading & otherState [*]
            if (a == 5) {
              return _State(!s.isLoading, s.term, s.items, s.otherState - 1);
            }

            throw a;
          },
        );

        await pumpEventQueue(times: 50);

        var termCount = 0;
        var itemsCount = 0;
        var otherStateCount = 0;
        var projectorCount = 0;

        final filtered = store.select3(
          (s) {
            ++termCount;
            return s.term;
          },
          (s) {
            ++itemsCount;
            return s.items;
          },
          (s) {
            ++otherStateCount;
            return s.otherState.round();
          },
          (String? term, BuiltList<String> items, int otherState) {
            ++projectorCount;
            return items
                .where((i) => i.contains(term ?? ''))
                .take(otherState)
                .toBuiltList();
          },
        );

        expect(filtered.requireValue, <String>[].build());
        final future = expectLater(
          filtered,
          emitsInOrder(<Object>[
            ['0', '1'].build(),
            ['4'].build(),
          ]),
        );

        final numberOfActions = 6;
        for (var i = 0; i < numberOfActions; i++) {
          store.dispatch(i);
        }
        await pumpEventQueue(times: 50);
        await future;

        expect(termCount,
            numberOfActions + 1); // inc. calling to produce seed value
        expect(itemsCount,
            numberOfActions + 1); // inc. calling to produce seed value
        expect(otherStateCount,
            numberOfActions + 1); // inc. calling to produce seed value
        expect(projectorCount,
            4 + 1); // 4 [*] and inc. calling to produce seed value
      });
    });
  });
}

class _State {
  final bool isLoading;
  final String? term;
  final BuiltList<String> items;
  final double otherState;

  _State(this.isLoading, this.term, this.items, this.otherState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _State &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          term == other.term &&
          items == other.items &&
          otherState == other.otherState;

  @override
  int get hashCode =>
      isLoading.hashCode ^ term.hashCode ^ items.hashCode ^ otherState.hashCode;

  @override
  String toString() =>
      '_State{isLoading: $isLoading, term: $term, items: $items, otherState: $otherState}';
}
