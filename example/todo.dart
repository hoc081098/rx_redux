import 'dart:async';

import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

/// Actions
class Action {
  final Todo todo;
  final ActionType type;

  const Action(this.todo, this.type);

  @override
  String toString() => 'Action { ${todo.id}, $type }';
}

enum ActionType {
  add,
  remove,
  toggle,
  //
  added,
  removed,
  toggled,
}

/// View state
class Todo {
  final int id;
  final String title;
  final bool completed;

  const Todo(this.id, this.title, this.completed);

  @override
  String toString() => 'Todo { $id, $completed }';
}

class ViewState {
  final List<Todo> todos;

  const ViewState(this.todos);

  @override
  String toString() => 'ViewState { ${todos.length} }';
}

/// Reducer
ViewState reducer(ViewState vs, Action action) {
  switch (action.type) {
    case ActionType.add:
      return vs;
    case ActionType.remove:
      return vs;
    case ActionType.toggle:
      return vs;
    case ActionType.added:
      return ViewState([...vs.todos, action.todo]);
    case ActionType.removed:
      return ViewState(
        vs.todos.where((t) => t.id != action.todo.id).toList(),
      );
    case ActionType.toggled:
      final todos = vs.todos
          .map((t) =>
              t.id != action.todo.id ? t : Todo(t.id, t.title, !t.completed))
          .toList(growable: false);
      return ViewState(todos);
    default:
      return vs;
  }
}

/// Side effects

// ignore: prefer_function_declarations_over_variables
final SideEffect<Action, ViewState> addTodoEffect = (action$, state) => action$
    .where((event) => event.type == ActionType.add)
    .map((event) => event.todo)
    .flatMap(
      (todo) => Rx.timer(
        Action(todo, ActionType.added),
        const Duration(milliseconds: 300),
      ),
    );

Stream<Action> removeTodoEffect(
  Stream<Action> action$,
  GetState<ViewState> state,
) {
  Stream<Action> executeRemove(Todo todo) async* {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield Action(todo, ActionType.removed);
  }

  return action$
      .where((event) => event.type == ActionType.remove)
      .map((action) => action.todo)
      .flatMap(executeRemove);
}

// ignore: prefer_function_declarations_over_variables
final SideEffect<Action, ViewState> toggleTodoEffect = (action$, state) {
  Stream<Action> executeToggle(Todo todo) async* {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield Action(todo, ActionType.toggled);
  }

  return action$
      .where((event) => event.type == ActionType.toggle)
      .map((action) => action.todo)
      .flatMap(executeToggle);
};

Future<void> delay() => Future<void>.delayed(const Duration(seconds: 1));

void main() async {
  final store = RxReduxStore(
    initialState: ViewState([]),
    sideEffects: [addTodoEffect, removeTodoEffect, toggleTodoEffect],
    reducer: reducer,
    logger: rxReduxDefaultLogger,
  );

  store.stateStream.listen((event) => print('~> State : $event'));
  store.actionStream.listen((event) => print('~> Action: $event'));

  for (var i = 0; i < 5; i++) {
    store.dispatch(Action(Todo(i, 'Title $i', i.isEven), ActionType.add));
  }
  await delay();

  for (var i = 0; i < 5; i++) {
    store.dispatch(Action(Todo(i, 'Title $i', i.isEven), ActionType.toggle));
  }
  await delay();

  for (var i = 0; i < 5; i++) {
    store.dispatch(Action(Todo(i, 'Title $i', i.isEven), ActionType.remove));
  }
  await delay();

  await Future(() {});
  await store.dispose();
}
