import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

abstract class Action {}

class IncrementAction implements Action {}

class IncrementLoadedAction implements Action {}

class DecrementAction implements Action {}

class State {
  final int count;

  const State(this.count);

  @override
  String toString() => 'State{count=$count}';
}

main() async {
  final actions = PublishSubject<Action>();

  final state$ = reduxStore<State, Action>(
    actions: actions,
    initialStateSupplier: () => const State(0),
    reducer: (State state, Action action) {
      if (action is IncrementAction) {
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
          (_) async* {
            await Future.delayed(const Duration(milliseconds: 500));
            yield IncrementLoadedAction();
          },
        );
      }
    ],
  );

  state$.listen(print);

  () async {
    for (int i = 0; i < 10; i++) {
      if (i.isEven) {
        actions.add(IncrementAction());
      } else {
        actions.add(DecrementAction());
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }();

  await Future.delayed(const Duration(seconds: 5));
}
