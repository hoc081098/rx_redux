import 'package:meta/meta.dart';
import 'package:rx_redux/rx_redux.dart';

@sealed
abstract class Action {}

class Increment implements Action {
  final int number;

  Increment(this.number);
}

class Decrement implements Action {
  final int number;

  Decrement(this.number);
}

class State {
  final int value;

  State(this.value);

  @override
  String toString() => 'State{value: $value}';
}

void main() async {
  final store = RxReduxStore<Action, State>(
    initialState: State(0),
    sideEffects: [],
    reducer: (state, action) {
      if (action is Increment) return State(state.value + action.number);
      if (action is Decrement) return State(state.value - action.number);
      return state;
    },
  );

  store.stateStream.listen(print);

  await Stream.periodic(const Duration(seconds: 1), (i) => i + 1)
      .take(10)
      .map((i) => i.isEven ? Increment(i) : Decrement(i))
      .forEach(store.dispatch);

  await Future(() {});
  await store.dispose();
}
