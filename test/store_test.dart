import 'package:built_collection/built_collection.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import 'utils.dart';

enum Action {
  action1,
  action2,
  action3,
  actionSideEffect1,
  actionSideEffect2,
  actionSideEffect3,
  actionNoOp
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
      test('select', () async {
        final store = RxReduxStore<int, String>(
          initialState: '',
          sideEffects: [],
          reducer: (s, a) => a.toString(),
        );

        final length$ = store.select((s) => s.length);
        expect(length$.value, 0);
        expect(
          length$,
          emitsInOrder(<Object>[
            1,
            2,
            3,
            4,
            emitsDone,
          ]),
        );

        await pumpEventQueue(times: 50);

        for (var i = 0; i <= 1000; i += 10) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 50);
        await store.dispose();
      });

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
          equals2: (BuiltList<String> prev, BuiltList<String> next) =>
              prev == next,
        );

        expect(filtered.value, <String>[].build());
        final future = expectLater(
          filtered,
          emitsInOrder(<Object>[
            List.generate(10, (i) => i.toString()).build(),
            ['4'].build(),
            emitsDone,
          ]),
        );

        final numberOfActions = 6;
        for (var i = 0; i < numberOfActions; i++) {
          store.dispatch(i);
        }
        await pumpEventQueue(times: 50);
        await store.dispose();
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
          equals3: (int prev, int next) => prev == next,
        );

        expect(filtered.value, <String>[].build());
        final future = expectLater(
          filtered,
          emitsInOrder(<Object>[
            ['0', '1'].build(),
            ['4'].build(),
            emitsDone,
          ]),
        );

        final numberOfActions = 6;
        for (var i = 0; i < numberOfActions; i++) {
          store.dispatch(i);
        }
        await pumpEventQueue(times: 50);
        await store.dispose();
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

      test('select4', () async {
        final initial = Tuple5(0, 1.0, '', true, <String>[].build());

        final store = RxReduxStore<int,
            Tuple5<int, double, String, bool, BuiltList<String>>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem5(s.item5.rebuild((b) => b.remove('01')));
              case 2:
                return s.withItem1(s.item1 + 1);
              case 3:
                return s.withItem2(s.item2 + 2);
              case 4:
                return s.withItem5(s.item5.rebuild((b) => b.add('01')));
              case 5:
                return s;
              case 6:
                return s.withItem3(s.item3 + '3');
              case 7:
                return s.withItem4(!s.item4);
              case 8:
                return s.withItem5(s.item5.rebuild((b) => b.add('5')));
              default:
                throw a;
            }
          },
        );

        final tuple$ = store.select4(
          expectAsync1((state) => state.item1, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item2, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item3, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item4, count: 7 + 1),
          // 7 action causes state changed
          expectAsync4(
            (int subState1, double subState2, String subState3,
                    bool subState4) =>
                Tuple4(subState1, subState2, subState3, subState4),
            count: 4 + 1, // inc. calling to produce seed value
          ),
          equals3: (String prev, String next) => prev == next,
        );

        final tuple4 = Tuple4<int, double, String, bool>(0, 1.0, '', true);
        expect(tuple$.value, tuple4);
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple4(0, 1.0, '', false), // 7
            Tuple4(0, 1.0, '3', false), // 6
            Tuple4(0, 3.0, '3', false), // 3
            Tuple4(1, 3.0, '3', false), // 2
            emitsDone,
          ]),
        );

        for (var i = 8; i >= 0; i--) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;
      });

      test('select5', () async {
        final initial = Tuple6(
          0,
          1.0,
          '',
          true,
          <String>[].build(),
          <String, int>{}.build(),
        );

        final store = RxReduxStore<
            int,
            Tuple6<int, double, String, bool, BuiltList<String>,
                BuiltMap<String, int>>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem1(s.item1 + a); // [item 1]
              case 2:
                return s.withItem2(s.item2 + a); // [item 2]
              case 3:
                return s.withItem6(
                    s.item6.rebuild((b) => b['@'] = a)); // ------------
              case 4:
                return s.withItem3(s.item3 + a.toString()); // [item 3]
              case 5:
                return s.withItem4(!s.item4); // [item 4]
              case 6:
                return s.withItem6(
                    s.item6.rebuild((b) => b.remove('@'))); // ------------
              case 7:
                return s.withItem5(
                    s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
              case 8:
                return s;
              default:
                throw a;
            }
          },
        );

        final tuple$ = store.select5(
          expectAsync1((state) => state.item1, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item2, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item3, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item4, count: 7 + 1),
          // 7 action causes state changed
          expectAsync1((state) => state.item5, count: 7 + 1),
          // 7 action causes state changed
          expectAsync5(
            (int subState1, double subState2, String subState3, bool subState4,
                    BuiltList<String> subState5) =>
                Tuple5(subState1, subState2, subState3, subState4, subState5),
            count: 5 + 1, // inc. calling to produce seed value
          ),
          equals3: (String prev, String next) => prev == next,
        );

        expect(tuple$.value, Tuple5(0, 1.0, '', true, <String>[].build()));
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple5(1, 1.0, '', true, <String>[].build()),
            Tuple5(1, 3.0, '', true, <String>[].build()),
            Tuple5(1, 3.0, '4', true, <String>[].build()),
            Tuple5(1, 3.0, '4', false, <String>[].build()),
            Tuple5(1, 3.0, '4', false, <String>['7'].build()),
            emitsDone,
          ]),
        );

        for (var i = 0; i <= 8; i++) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;
      });

      test('select6', () async {
        final initial = Tuple7(
          0,
          1.0,
          '',
          true,
          <String>[].build(),
          <String, int>{}.build(),
          <String>{}.build(),
        );

        final store = RxReduxStore<
            int,
            Tuple7<int, double, String, bool, BuiltList<String>,
                BuiltMap<String, int>, BuiltSet<String>>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem1(s.item1 + a); // [item 1]
              case 2:
                return s.withItem2(s.item2 + a); // [item 2]
              case 3:
                return s.withItem7(s.item7
                    .rebuild((b) => b.add(a.toString()))); // ------------
              case 4:
                return s.withItem3(s.item3 + a.toString()); // [item 3]
              case 5:
                return s.withItem4(!s.item4); // [item 4]
              case 6:
                return s.withItem7(s.item7
                    .rebuild((b) => b.add(a.toString()))); // ------------
              case 7:
                return s.withItem5(
                    s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
              case 8:
                return s
                    .withItem6(s.item6.rebuild((b) => b['@'] = a)); // [item 6]
              case 9:
                return s;
              default:
                throw a;
            }
          },
        );

        final tuple$ = store.select6(
          expectAsync1((state) => state.item1, count: 8 + 1),
          // 8 action causes state changed
          expectAsync1((state) => state.item2, count: 8 + 1),
          // 8 action causes state changed
          expectAsync1((state) => state.item3, count: 8 + 1),
          // 8 action causes state changed
          expectAsync1((state) => state.item4, count: 8 + 1),
          // 8 action causes state changed
          expectAsync1((state) => state.item5, count: 8 + 1),
          // 8 action causes state changed
          expectAsync1((state) => state.item6, count: 8 + 1),
          // 8 action causes state changed
          expectAsync6(
            (int subState1,
                    double subState2,
                    String subState3,
                    bool subState4,
                    BuiltList<String> subState5,
                    BuiltMap<String, int> subState6) =>
                Tuple6(subState1, subState2, subState3, subState4, subState5,
                    subState6),
            count: 6 + 1, // inc. calling to produce seed value
          ),
          equals3: (String prev, String next) => prev == next,
        );

        expect(
            tuple$.value,
            Tuple6(
                0, 1.0, '', true, <String>[].build(), <String, int>{}.build()));
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple6(
                1, 1.0, '', true, <String>[].build(), <String, int>{}.build()),
            Tuple6(
                1, 3.0, '', true, <String>[].build(), <String, int>{}.build()),
            Tuple6(
                1, 3.0, '4', true, <String>[].build(), <String, int>{}.build()),
            Tuple6(1, 3.0, '4', false, <String>[].build(),
                <String, int>{}.build()),
            Tuple6(1, 3.0, '4', false, <String>['7'].build(),
                <String, int>{}.build()),
            Tuple6(1, 3.0, '4', false, <String>['7'].build(),
                <String, int>{'@': 8}.build()),
            emitsDone,
          ]),
        );

        for (var i = 0; i <= 9; i++) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;
      });

      test('select7', () async {
        final initial = Tuple8(
          0,
          1.0,
          '',
          true,
          <String>[].build(),
          <String, int>{}.build(),
          <String>{}.build(),
          BuiltListMultimap<String, int>.build((b) => b
            ..add('@', 1)
            ..add('@', 2)),
        );

        final store = RxReduxStore<
            int,
            Tuple8<
                int,
                double,
                String,
                bool,
                BuiltList<String>,
                BuiltMap<String, int>,
                BuiltSet<String>,
                BuiltListMultimap<String, int>>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem1(s.item1 + a); // [item 1]
              case 2:
                return s.withItem2(s.item2 + a); // [item 2]
              case 3:
                return s.withItem8(
                    s.item8.rebuild((b) => b.remove('@', 1))); // ------------
              case 4:
                return s.withItem3(s.item3 + a.toString()); // [item 3]
              case 5:
                return s.withItem4(!s.item4); // [item 4]
              case 6:
                return s.withItem8(
                    s.item8.rebuild((b) => b.removeAll('@'))); // ------------
              case 7:
                return s.withItem5(
                    s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
              case 8:
                return s
                    .withItem6(s.item6.rebuild((b) => b['@'] = a)); // [item 6]
              case 9:
                return s.withItem8(
                    s.item8.rebuild((b) => b.add('#', a))); // ------------
              case 10:
                return s.withItem7(
                    s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
              case 11:
                return s;
              default:
                throw a;
            }
          },
        );

        var projectCount = 0;

        final tuple$ = store.select7(
          expectAsync1((state) => state.item1, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item2, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item3, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item4, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item5, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item6, count: 10 + 1),
          // 10 action causes state changed
          expectAsync1((state) => state.item7, count: 10 + 1),
          // 10 action causes state changed
          (int subState1,
              double subState2,
              String subState3,
              bool subState4,
              BuiltList<String> subState5,
              BuiltMap<String, int> subState6,
              BuiltSet<String> subState7) {
            ++projectCount;
            return Tuple7(subState1, subState2, subState3, subState4, subState5,
                subState6, subState7);
          },
          equals3: (String prev, String next) => prev == next,
        );

        expect(
          tuple$.value,
          Tuple7(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
          ),
        );
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple7(
              1,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '4',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '4',
              false,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{}.build(),
            ),
            Tuple7(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
            ),
            emitsDone,
          ]),
        );

        for (var i = 0; i <= 11; i++) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;

        expect(projectCount, 7 + 1); // seed value + 7 items.
      });

      test('select8', () async {
        final initial = Tuple9(
          0,
          1.0,
          '',
          true,
          <String>[].build(),
          <String, int>{}.build(),
          <String>{}.build(),
          BuiltListMultimap<String, int>.build((b) => b
            ..add('@', 1)
            ..add('@', 2)),
          BuiltSetMultimap<String, int>.build((b) => b
            ..add('@', 1)
            ..add('@', 2)),
        );

        final store = RxReduxStore<
            int,
            Tuple9<
                int,
                double,
                String,
                bool,
                BuiltList<String>,
                BuiltMap<String, int>,
                BuiltSet<String>,
                BuiltListMultimap<String, int>,
                BuiltSetMultimap<String, int>>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem1(s.item1 + a); // [item 1]
              case 2:
                return s.withItem2(s.item2 + a); // [item 2]
              case 3:
                return s.withItem9(
                    s.item9.rebuild((b) => b.remove('@', 1))); // ------------
              case 4:
                return s.withItem3(s.item3 + a.toString()); // [item 3]
              case 5:
                return s.withItem4(!s.item4); // [item 4]
              case 6:
                return s.withItem9(
                    s.item9.rebuild((b) => b.removeAll('@'))); // ------------
              case 7:
                return s.withItem5(
                    s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
              case 8:
                return s
                    .withItem6(s.item6.rebuild((b) => b['@'] = a)); // [item 6]
              case 9:
                return s.withItem9(
                    s.item9.rebuild((b) => b.add('#', a))); // ------------
              case 10:
                return s.withItem7(
                    s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
              case 11:
                return s.withItem8(
                    s.item8.rebuild((b) => b.add('#', a))); // [item 8]
              case 12:
                return s;
              default:
                throw a;
            }
          },
        );

        var projectCount = 0;

        final tuple$ = store.select8(
          expectAsync1((state) => state.item1, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item2, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item3, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item4, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item5, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item6, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item7, count: 11 + 1),
          // 11 action causes state changed
          expectAsync1((state) => state.item8, count: 11 + 1),
          // 11 action causes state changed
          (int subState1,
              double subState2,
              String subState3,
              bool subState4,
              BuiltList<String> subState5,
              BuiltMap<String, int> subState6,
              BuiltSet<String> subState7,
              BuiltListMultimap<String, int> subState8) {
            ++projectCount;
            return Tuple8(subState1, subState2, subState3, subState4, subState5,
                subState6, subState7, subState8);
          },
          equals3: (String prev, String next) => prev == next,
        );

        expect(
          tuple$.value,
          Tuple8(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
            BuiltListMultimap<String, int>({
              '@': [1, 2]
            }),
          ),
        );
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple8(
              1,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              false,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2]
              }),
            ),
            Tuple8(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
              BuiltListMultimap<String, int>(<String, List<int>>{
                '@': [1, 2],
                '#': [11]
              }),
            ),
            emitsDone,
          ]),
        );

        for (var i = 0; i <= 12; i++) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;

        expect(projectCount, 8 + 1); // seed value + 8 items.
      });

      test('select9', () async {
        final initial = Tuple10(
          0,
          1.0,
          '',
          true,
          <String>[].build(),
          <String, int>{}.build(),
          <String>{}.build(),
          BuiltListMultimap<String, int>.build((b) => b
            ..add('@', 1)
            ..add('@', 2)),
          BuiltSetMultimap<String, int>.build((b) => b
            ..add('@', 1)
            ..add('@', 2)),
          DateTime(1998, DateTime.october, 8),
        );

        final store = RxReduxStore<
            int,
            Tuple10<
                int,
                double,
                String,
                bool,
                BuiltList<String>,
                BuiltMap<String, int>,
                BuiltSet<String>,
                BuiltListMultimap<String, int>,
                BuiltSetMultimap<String, int>,
                DateTime>>(
          initialState: initial,
          sideEffects: [],
          reducer: (s, a) {
            switch (a) {
              case 0:
                return s;
              case 1:
                return s.withItem1(s.item1 + a); // [item 1]
              case 2:
                return s.withItem2(s.item2 + a); // [item 2]
              case 3:
                return s.withItem10(
                    s.item10.add(const Duration(hours: 1))); // ------------
              case 4:
                return s.withItem3(s.item3 + a.toString()); // [item 3]
              case 5:
                return s.withItem4(!s.item4); // [item 4]
              case 6:
                return s.withItem10(
                    s.item10.add(const Duration(hours: 1))); // ------------
              case 7:
                return s.withItem5(
                    s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
              case 8:
                return s
                    .withItem6(s.item6.rebuild((b) => b['@'] = a)); // [item 6]
              case 9:
                return s.withItem10(
                    s.item10.add(const Duration(hours: 1))); // ------------
              case 10:
                return s.withItem7(
                    s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
              case 11:
                return s.withItem8(
                    s.item8.rebuild((b) => b.add('#', a))); // [item 8]
              case 12:
                return s.withItem9(
                    s.item9.rebuild((b) => b.add('#', a))); // [item 9]
              case 13:
                return s;
              default:
                throw a;
            }
          },
        );

        var projectCount = 0;

        final tuple$ = store.select9(
          expectAsync1((state) => state.item1, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item2, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item3, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item4, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item5, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item6, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item7, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item8, count: 12 + 1),
          // 12 action causes state changed
          expectAsync1((state) => state.item9, count: 12 + 1),
          // 12 action causes state changed
          (int subState1,
              double subState2,
              String subState3,
              bool subState4,
              BuiltList<String> subState5,
              BuiltMap<String, int> subState6,
              BuiltSet<String> subState7,
              BuiltListMultimap<String, int> subState8,
              BuiltSetMultimap<String, int> subState9) {
            ++projectCount;
            return Tuple9(subState1, subState2, subState3, subState4, subState5,
                subState6, subState7, subState8, subState9);
          },
          equals3: (String prev, String next) => prev == next,
        );

        expect(
          tuple$.value,
          Tuple9(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
            BuiltListMultimap<String, int>({
              '@': [1, 2]
            }),
            BuiltSetMultimap<String, int>({
              '@': {1, 2}
            }),
          ),
        );
        final future = expectLater(
          tuple$,
          emitsInOrder(<Object>[
            Tuple9(
              1,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2],
                '#': [11]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
            Tuple9(
              1,
              3.0,
              '4',
              false,
              <String>['7'].build(),
              <String, int>{'@': 8}.build(),
              <String>{'10'}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2],
                '#': [11]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2},
                '#': {12}
              }),
            ),
            emitsDone,
          ]),
        );

        for (var i = 0; i <= 13; i++) {
          i.dispatchTo(store);
        }
        await pumpEventQueue(times: 100);
        await store.dispose();
        await future;

        expect(projectCount, 9 + 1); // seed value + 9 items.
      });

      group('selectMany', () {
        test('assert', () {
          final store = RxReduxStore<int, String>(
            initialState: 'initialState',
            sideEffects: [],
            reducer: (s, a) => s,
          );
          expect(
            () => store.selectMany(
              [(s) => s.length, (s) => s.isEmpty ? null : s[0]],
              [null, null, null],
              (subStates) => subStates,
            ),
            throwsArgumentError,
          );
          expect(
            () => store.selectMany<Object, Object>(
              [],
              [],
              (subStates) => subStates,
            ),
            throwsArgumentError,
          );
          expect(
            () => store.selectMany(
              [(s) => s.length],
              [null],
              (subStates) => subStates,
            ),
            throwsArgumentError,
          );
        });

        test('~= select2', () async {
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

          final filtered = store.selectMany<Object?, BuiltList<String>>(
            [
              (s) {
                ++termCount;
                return s.term;
              },
              (s) {
                ++itemsCount;
                return s.items;
              }
            ],
            [null, null],
            (List<Object?> subStates) {
              ++projectorCount;
              return (subStates[1] as BuiltList<String>)
                  .where((i) => i.contains((subStates[0] as String?) ?? ''))
                  .toBuiltList();
            },
          );

          expect(filtered.value, <String>[].build());
          final future = expectLater(
            filtered,
            emitsInOrder(<Object>[
              List.generate(10, (i) => i.toString()).build(),
              ['4'].build(),
              emitsDone,
            ]),
          );

          final numberOfActions = 6;
          for (var i = 0; i < numberOfActions; i++) {
            store.dispatch(i);
          }
          await pumpEventQueue(times: 50);
          await store.dispose();
          await future;

          expect(termCount,
              numberOfActions + 1); // inc. calling to produce seed value
          expect(itemsCount,
              numberOfActions + 1); // inc. calling to produce seed value
          expect(projectorCount,
              2 + 1); // 2 [*] and inc. calling to produce seed value
        });

        test('~= select3', () async {
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

          final filtered = store.selectMany(
            [
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
            ],
            [null, null, null],
            (List<Object?> subStates) {
              ++projectorCount;

              final term = subStates[0] as String?;
              final items = subStates[1] as BuiltList<String>;
              final otherState = subStates[2] as int;

              return items
                  .where((i) => i.contains(term ?? ''))
                  .take(otherState)
                  .toBuiltList();
            },
          );

          expect(filtered.value, <String>[].build());
          final future = expectLater(
            filtered,
            emitsInOrder(<Object>[
              ['0', '1'].build(),
              ['4'].build(),
              emitsDone,
            ]),
          );

          final numberOfActions = 6;
          for (var i = 0; i < numberOfActions; i++) {
            store.dispatch(i);
          }
          await pumpEventQueue(times: 50);
          await store.dispose();
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

        test('~= select4', () async {
          final initial = Tuple5(0, 1.0, '', true, <String>[].build());

          final store = RxReduxStore<int,
              Tuple5<int, double, String, bool, BuiltList<String>>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem5(s.item5.rebuild((b) => b.remove('01')));
                case 2:
                  return s.withItem1(s.item1 + 1);
                case 3:
                  return s.withItem2(s.item2 + 2);
                case 4:
                  return s.withItem5(s.item5.rebuild((b) => b.add('01')));
                case 5:
                  return s;
                case 6:
                  return s.withItem3(s.item3 + '3');
                case 7:
                  return s.withItem4(!s.item4);
                case 8:
                  return s.withItem5(s.item5.rebuild((b) => b.add('5')));
                default:
                  throw a;
              }
            },
          );

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item2, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item3, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item4, count: 7 + 1),
              // 7 action causes state changed
            ],
            [null, null, null, null],
            expectAsync1(
              (List<Object?> subStates) => Tuple4(
                subStates[0] as int,
                subStates[1] as double,
                subStates[2] as String,
                subStates[3] as bool,
              ),
              count: 4 + 1, // inc. calling to produce seed value
            ),
          );

          final tuple4 = Tuple4<int, double, String, bool>(0, 1.0, '', true);
          expect(tuple$.value, tuple4);
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple4(0, 1.0, '', false), // 7
              Tuple4(0, 1.0, '3', false), // 6
              Tuple4(0, 3.0, '3', false), // 3
              Tuple4(1, 3.0, '3', false), // 2
              emitsDone,
            ]),
          );

          for (var i = 8; i >= 0; i--) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;
        });

        test('~= select5', () async {
          final initial = Tuple6(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
          );

          final store = RxReduxStore<
              int,
              Tuple6<int, double, String, bool, BuiltList<String>,
                  BuiltMap<String, int>>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem1(s.item1 + a); // [item 1]
                case 2:
                  return s.withItem2(s.item2 + a); // [item 2]
                case 3:
                  return s.withItem6(
                      s.item6.rebuild((b) => b['@'] = a)); // ------------
                case 4:
                  return s.withItem3(s.item3 + a.toString()); // [item 3]
                case 5:
                  return s.withItem4(!s.item4); // [item 4]
                case 6:
                  return s.withItem6(
                      s.item6.rebuild((b) => b.remove('@'))); // ------------
                case 7:
                  return s.withItem5(
                      s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
                case 8:
                  return s;
                default:
                  throw a;
              }
            },
          );

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item2, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item3, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item4, count: 7 + 1),
              // 7 action causes state changed
              expectAsync1((state) => state.item5, count: 7 + 1),
              // 7 action causes state changed
            ],
            [null, null, null, null, null],
            expectAsync1(
              (subStates) {
                return Tuple5(
                  subStates[0] as int,
                  subStates[1] as double,
                  subStates[2] as String,
                  subStates[3] as bool,
                  subStates[4] as BuiltList<String>,
                );
              },
              count: 5 + 1, // inc. calling to produce seed value
            ),
          );

          expect(tuple$.value, Tuple5(0, 1.0, '', true, <String>[].build()));
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple5(1, 1.0, '', true, <String>[].build()),
              Tuple5(1, 3.0, '', true, <String>[].build()),
              Tuple5(1, 3.0, '4', true, <String>[].build()),
              Tuple5(1, 3.0, '4', false, <String>[].build()),
              Tuple5(1, 3.0, '4', false, <String>['7'].build()),
              emitsDone,
            ]),
          );

          for (var i = 0; i <= 8; i++) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;
        });

        test('~= select6', () async {
          final initial = Tuple7(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
          );

          final store = RxReduxStore<
              int,
              Tuple7<int, double, String, bool, BuiltList<String>,
                  BuiltMap<String, int>, BuiltSet<String>>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem1(s.item1 + a); // [item 1]
                case 2:
                  return s.withItem2(s.item2 + a); // [item 2]
                case 3:
                  return s.withItem7(s.item7
                      .rebuild((b) => b.add(a.toString()))); // ------------
                case 4:
                  return s.withItem3(s.item3 + a.toString()); // [item 3]
                case 5:
                  return s.withItem4(!s.item4); // [item 4]
                case 6:
                  return s.withItem7(s.item7
                      .rebuild((b) => b.add(a.toString()))); // ------------
                case 7:
                  return s.withItem5(
                      s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
                case 8:
                  return s.withItem6(
                      s.item6.rebuild((b) => b['@'] = a)); // [item 6]
                case 9:
                  return s;
                default:
                  throw a;
              }
            },
          );

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 8 + 1),
              // 8 action causes state changed
              expectAsync1((state) => state.item2, count: 8 + 1),
              // 8 action causes state changed
              expectAsync1((state) => state.item3, count: 8 + 1),
              // 8 action causes state changed
              expectAsync1((state) => state.item4, count: 8 + 1),
              // 8 action causes state changed
              expectAsync1((state) => state.item5, count: 8 + 1),
              // 8 action causes state changed
              expectAsync1((state) => state.item6, count: 8 + 1),
              // 8 action causes state changed
            ],
            [null, null, null, null, null, null],
            expectAsync1(
              (subStates) => Tuple6(
                subStates[0] as int,
                subStates[1] as double,
                subStates[2] as String,
                subStates[3] as bool,
                subStates[4] as BuiltList<String>,
                subStates[5] as BuiltMap<String, int>,
              ),
              count: 6 + 1, // inc. calling to produce seed value
            ),
          );

          expect(
              tuple$.value,
              Tuple6(0, 1.0, '', true, <String>[].build(),
                  <String, int>{}.build()));
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple6(1, 1.0, '', true, <String>[].build(),
                  <String, int>{}.build()),
              Tuple6(1, 3.0, '', true, <String>[].build(),
                  <String, int>{}.build()),
              Tuple6(1, 3.0, '4', true, <String>[].build(),
                  <String, int>{}.build()),
              Tuple6(1, 3.0, '4', false, <String>[].build(),
                  <String, int>{}.build()),
              Tuple6(1, 3.0, '4', false, <String>['7'].build(),
                  <String, int>{}.build()),
              Tuple6(1, 3.0, '4', false, <String>['7'].build(),
                  <String, int>{'@': 8}.build()),
              emitsDone,
            ]),
          );

          for (var i = 0; i <= 9; i++) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;
        });

        test('~= select7', () async {
          final initial = Tuple8(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
            BuiltListMultimap<String, int>.build((b) => b
              ..add('@', 1)
              ..add('@', 2)),
          );

          final store = RxReduxStore<
              int,
              Tuple8<
                  int,
                  double,
                  String,
                  bool,
                  BuiltList<String>,
                  BuiltMap<String, int>,
                  BuiltSet<String>,
                  BuiltListMultimap<String, int>>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem1(s.item1 + a); // [item 1]
                case 2:
                  return s.withItem2(s.item2 + a); // [item 2]
                case 3:
                  return s.withItem8(
                      s.item8.rebuild((b) => b.remove('@', 1))); // ------------
                case 4:
                  return s.withItem3(s.item3 + a.toString()); // [item 3]
                case 5:
                  return s.withItem4(!s.item4); // [item 4]
                case 6:
                  return s.withItem8(
                      s.item8.rebuild((b) => b.removeAll('@'))); // ------------
                case 7:
                  return s.withItem5(
                      s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
                case 8:
                  return s.withItem6(
                      s.item6.rebuild((b) => b['@'] = a)); // [item 6]
                case 9:
                  return s.withItem8(
                      s.item8.rebuild((b) => b.add('#', a))); // ------------
                case 10:
                  return s.withItem7(
                      s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
                case 11:
                  return s;
                default:
                  throw a;
              }
            },
          );

          var projectCount = 0;

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item2, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item3, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item4, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item5, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item6, count: 10 + 1),
              // 10 action causes state changed
              expectAsync1((state) => state.item7, count: 10 + 1),
              // 10 action causes state changed
            ],
            List.filled(7, null),
            (subStates) {
              ++projectCount;

              final subState1 = subStates[0] as int;
              final subState2 = subStates[1] as double;
              final subState3 = subStates[2] as String;
              final subState4 = subStates[3] as bool;
              final subState5 = subStates[4] as BuiltList<String>;
              final subState6 = subStates[5] as BuiltMap<String, int>;
              final subState7 = subStates[6] as BuiltSet<String>;
              return Tuple7(subState1, subState2, subState3, subState4,
                  subState5, subState6, subState7);
            },
          );

          expect(
            tuple$.value,
            Tuple7(
              0,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
            ),
          );
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple7(
                1,
                1.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '4',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '4',
                false,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{}.build(),
              ),
              Tuple7(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
              ),
              emitsDone,
            ]),
          );

          for (var i = 0; i <= 11; i++) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;

          expect(projectCount, 7 + 1); // seed value + 7 items.
        });

        test('~= select8', () async {
          final initial = Tuple9(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
            BuiltListMultimap<String, int>.build((b) => b
              ..add('@', 1)
              ..add('@', 2)),
            BuiltSetMultimap<String, int>.build((b) => b
              ..add('@', 1)
              ..add('@', 2)),
          );

          final store = RxReduxStore<
              int,
              Tuple9<
                  int,
                  double,
                  String,
                  bool,
                  BuiltList<String>,
                  BuiltMap<String, int>,
                  BuiltSet<String>,
                  BuiltListMultimap<String, int>,
                  BuiltSetMultimap<String, int>>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem1(s.item1 + a); // [item 1]
                case 2:
                  return s.withItem2(s.item2 + a); // [item 2]
                case 3:
                  return s.withItem9(
                      s.item9.rebuild((b) => b.remove('@', 1))); // ------------
                case 4:
                  return s.withItem3(s.item3 + a.toString()); // [item 3]
                case 5:
                  return s.withItem4(!s.item4); // [item 4]
                case 6:
                  return s.withItem9(
                      s.item9.rebuild((b) => b.removeAll('@'))); // ------------
                case 7:
                  return s.withItem5(
                      s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
                case 8:
                  return s.withItem6(
                      s.item6.rebuild((b) => b['@'] = a)); // [item 6]
                case 9:
                  return s.withItem9(
                      s.item9.rebuild((b) => b.add('#', a))); // ------------
                case 10:
                  return s.withItem7(
                      s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
                case 11:
                  return s.withItem8(
                      s.item8.rebuild((b) => b.add('#', a))); // [item 8]
                case 12:
                  return s;
                default:
                  throw a;
              }
            },
          );

          var projectCount = 0;

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item2, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item3, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item4, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item5, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item6, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item7, count: 11 + 1),
              // 11 action causes state changed
              expectAsync1((state) => state.item8, count: 11 + 1),
              // 11 action causes state changed
            ],
            List.filled(8, null),
            (subStates) {
              ++projectCount;
              return Tuple8(
                subStates[0] as int,
                subStates[1] as double,
                subStates[2] as String,
                subStates[3] as bool,
                subStates[4] as BuiltList<String>,
                subStates[5] as BuiltMap<String, int>,
                subStates[6] as BuiltSet<String>,
                subStates[7] as BuiltListMultimap<String, int>,
              );
            },
          );

          expect(
            tuple$.value,
            Tuple8(
              0,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
            ),
          );
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple8(
                1,
                1.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                false,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2]
                }),
              ),
              Tuple8(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
                BuiltListMultimap<String, int>(<String, List<int>>{
                  '@': [1, 2],
                  '#': [11]
                }),
              ),
              emitsDone,
            ]),
          );

          for (var i = 0; i <= 12; i++) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;

          expect(projectCount, 8 + 1); // seed value + 8 items.
        });

        test('~= select9', () async {
          final initial = Tuple10(
            0,
            1.0,
            '',
            true,
            <String>[].build(),
            <String, int>{}.build(),
            <String>{}.build(),
            BuiltListMultimap<String, int>.build((b) => b
              ..add('@', 1)
              ..add('@', 2)),
            BuiltSetMultimap<String, int>.build((b) => b
              ..add('@', 1)
              ..add('@', 2)),
            DateTime(1998, DateTime.october, 8),
          );

          final store = RxReduxStore<
              int,
              Tuple10<
                  int,
                  double,
                  String,
                  bool,
                  BuiltList<String>,
                  BuiltMap<String, int>,
                  BuiltSet<String>,
                  BuiltListMultimap<String, int>,
                  BuiltSetMultimap<String, int>,
                  DateTime>>(
            initialState: initial,
            sideEffects: [],
            reducer: (s, a) {
              switch (a) {
                case 0:
                  return s;
                case 1:
                  return s.withItem1(s.item1 + a); // [item 1]
                case 2:
                  return s.withItem2(s.item2 + a); // [item 2]
                case 3:
                  return s.withItem10(
                      s.item10.add(const Duration(hours: 1))); // ------------
                case 4:
                  return s.withItem3(s.item3 + a.toString()); // [item 3]
                case 5:
                  return s.withItem4(!s.item4); // [item 4]
                case 6:
                  return s.withItem10(
                      s.item10.add(const Duration(hours: 1))); // ------------
                case 7:
                  return s.withItem5(
                      s.item5.rebuild((b) => b.add(a.toString()))); // [item 5]
                case 8:
                  return s.withItem6(
                      s.item6.rebuild((b) => b['@'] = a)); // [item 6]
                case 9:
                  return s.withItem10(
                      s.item10.add(const Duration(hours: 1))); // ------------
                case 10:
                  return s.withItem7(
                      s.item7.rebuild((b) => b.add(a.toString()))); // [item 7]
                case 11:
                  return s.withItem8(
                      s.item8.rebuild((b) => b.add('#', a))); // [item 8]
                case 12:
                  return s.withItem9(
                      s.item9.rebuild((b) => b.add('#', a))); // [item 9]
                case 13:
                  return s;
                default:
                  throw a;
              }
            },
          );

          var projectCount = 0;

          final tuple$ = store.selectMany(
            [
              expectAsync1((state) => state.item1, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item2, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item3, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item4, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item5, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item6, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item7, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item8, count: 12 + 1),
              // 12 action causes state changed
              expectAsync1((state) => state.item9, count: 12 + 1),
              // 12 action causes state changed
            ],
            List.filled(9, null),
            (subStates) {
              ++projectCount;

              return Tuple9(
                subStates[0] as int,
                subStates[1] as double,
                subStates[2] as String,
                subStates[3] as bool,
                subStates[4] as BuiltList<String>,
                subStates[5] as BuiltMap<String, int>,
                subStates[6] as BuiltSet<String>,
                subStates[7] as BuiltListMultimap<String, int>,
                subStates[8] as BuiltSetMultimap<String, int>,
              );
            },
          );

          expect(
            tuple$.value,
            Tuple9(
              0,
              1.0,
              '',
              true,
              <String>[].build(),
              <String, int>{}.build(),
              <String>{}.build(),
              BuiltListMultimap<String, int>({
                '@': [1, 2]
              }),
              BuiltSetMultimap<String, int>({
                '@': {1, 2}
              }),
            ),
          );
          final future = expectLater(
            tuple$,
            emitsInOrder(<Object>[
              Tuple9(
                1,
                1.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                true,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>[].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2],
                  '#': [11]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2}
                }),
              ),
              Tuple9(
                1,
                3.0,
                '4',
                false,
                <String>['7'].build(),
                <String, int>{'@': 8}.build(),
                <String>{'10'}.build(),
                BuiltListMultimap<String, int>({
                  '@': [1, 2],
                  '#': [11]
                }),
                BuiltSetMultimap<String, int>({
                  '@': {1, 2},
                  '#': {12}
                }),
              ),
              emitsDone,
            ]),
          );

          for (var i = 0; i <= 13; i++) {
            i.dispatchTo(store);
          }
          await pumpEventQueue(times: 100);
          await store.dispose();
          await future;

          expect(projectCount, 9 + 1); // seed value + 9 items.
        });
      });
    });
  });
}
