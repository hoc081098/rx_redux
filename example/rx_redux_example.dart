import 'dart:async';

import 'package:pedantic/pedantic.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

abstract class Action {}

class IncrementAction implements Action {
  final int p;

  IncrementAction(this.p);

  @override
  String toString() => 'IncrementAction{p=$p}';
}

class IncrementLoadedAction implements Action {
  final int p;

  IncrementLoadedAction(this.p);

  @override
  String toString() => 'IncrementLoadedAction{p=$p}';
}

class DecrementAction implements Action {}

class State {
  final int count;

  const State(this.count);

  @override
  String toString() => 'State{count=$count}';
}

main() async {
  final actions = PublishSubject<Action>(
    onCancel: () => print('[action onCancel]'),
    onListen: () => print('[action onListen]'),
  );

  final state$ = reduxStore<State, Action>(
    actions: actions.doOnData((action) => print('[dispatch] action=$action')),
    initialStateSupplier: () => const State(0),
    reducer: (State state, Action action) {
      if (action is IncrementAction) {
        // return State(action.p ~/ 0);
        return state;
      }
      if (action is IncrementLoadedAction) {
        return State(state.count + 10);
      }
      if (action is DecrementAction) {
        return State(state.count - 1);
      }
      return state;
    },
    sideEffects: <SideEffect<State, Action>>[
      (actions, state) {
        return actions.ofType(TypeToken<IncrementAction>()).concatMap(
          (incrementAction) async* {
            await Future.delayed(const Duration(milliseconds: 1000));
            print('[in side effect] access state=${state()}');
            yield IncrementLoadedAction(incrementAction.p);
          },
        ).doOnData((action) => print('[side effect] action=$action'));
      }
    ],
  );

  final sub = state$.doOnCancel(() => print('[state onCancel]')).listen(
        print,
        onError: print,
        onDone: () => print('[state onDone]'),
        cancelOnError: true,
      );

  unawaited(
    () async {
      for (int i = 0; i < 5; i++) {
        //  sub.pause();

        if (i.isEven) {
          actions.add(IncrementAction(i));
        } else {
          actions.add(DecrementAction());
        }

        await Future.delayed(const Duration(milliseconds: 300));
        // sub.resume();
      }

      print('continue');

      for (int i = 0; i < 5; i++) {
        print('continue $i');
        if (i.isEven) {
          actions.add(IncrementAction(i));
        } else {
          actions.add(DecrementAction());
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }(),
  );

  await Future.delayed(const Duration(seconds: 5));
}
