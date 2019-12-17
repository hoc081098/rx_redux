# Example

## [Pagination list (load more) (endless scrolling)](https://github.com/hoc081098/load_more_flutter_BLoC_pattern_RxDart_and_RxRedux/tree/master/lib/pages/rx_redux)

An example of how to load more data when scroll to end of list view using [rx_redux](https://pub.dev/packages/rx_redux).

## [Simple todo](https://gist.github.com/hoc081098/5e68efa923c98566143c9028b3748dc1)

```dart
import 'package:flutter/material.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';
import 'package:random_string/random_string.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.red),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

///
/// Actions
///

abstract class Action {}

class AddTodo implements Action {
  final Todo todo;

  AddTodo(this.todo);
}

class RemoveTodo implements Action {
  final Todo todo;

  RemoveTodo(this.todo);
}

class ToggleTodo implements Action {
  final Todo todo;

  ToggleTodo(this.todo);
}

class TodoAdded implements Action {
  final Todo todo;

  TodoAdded(this.todo);
}

class TodoRemoved implements Action {
  final Todo todo;

  TodoRemoved(this.todo);
}

class TodoToggled implements Action {
  final Todo todo;

  TodoToggled(this.todo);
}

///
/// View state
///

class Todo {
  final int id;
  final String title;
  final bool completed;

  const Todo(this.id, this.title, this.completed);
}

class ViewState {
  final List<Todo> todos;

  const ViewState(this.todos);
}

///
/// Reducer
///

ViewState _reducer(ViewState vs, Action action) {
  if (action is AddTodo) return vs;
  if (action is RemoveTodo) return vs;
  if (action is ToggleTodo) return vs;

  if (action is TodoAdded) {
    return ViewState([...vs.todos, action.todo]);
  }

  if (action is TodoRemoved) {
    return ViewState(
      vs.todos.where((t) => t.id != action.todo.id).toList(),
    );
  }

  if (action is TodoToggled) {
    return ViewState(
      vs.todos.map((t) {
        if (t.id != action.todo.id) {
          return t;
        } else {
          return Todo(
            t.id,
            t.title,
            !t.completed,
          );
        }
      }).toList(),
    );
  }

  return vs;
}

///
/// Side effects
///

final SideEffect<ViewState, Action> _addTodoEffect = (action$, state) {
  return action$.whereType<AddTodo>().map((action) => action.todo).flatMap(
    (todo) async* {
      await Future.delayed(const Duration(milliseconds: 500));
      yield TodoAdded(todo);
    },
  );
};

Stream<Action> _removeTodoEffect(
  Stream<Action> action$,
  StateAccessor state,
) {
  return action$.whereType<RemoveTodo>().map((action) => action.todo).flatMap(
    (todo) async* {
      await Future.delayed(const Duration(milliseconds: 500));
      yield TodoRemoved(todo);
    },
  );
}

final SideEffect<ViewState, Action> _toggleTodoEffect = (action$, state) {
  return action$
      .whereType<ToggleTodo>()
      .map((action) => action.todo)
      .flatMap((todo) async* {
        await Future.delayed(const Duration(milliseconds: 500));
        yield TodoToggled(todo);
      });
};

///
/// Home page's state
///

class _MyHomePageState extends State<MyHomePage> {
  static var _id = 0;
  final actionS = PublishSubject<Action>();
  ValueStream<ViewState> state$;

  @override
  void initState() {
    super.initState();

    const initialVS = ViewState([]);
    state$ = actionS
        .reduxStore<ViewState>(
            initialStateSupplier: () => initialVS,
            reducer: _reducer,
            sideEffects: [
              _addTodoEffect,
              _removeTodoEffect,
              _toggleTodoEffect,
            ],
          ),
        )
        .shareValueSeeded(initialVS);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RxRedux demo'),
      ),
      body: StreamBuilder<ViewState>(
        initialData: state$.value,
        stream: state$,
        builder: (context, snapshot) {
          final todos = snapshot.data.todos;

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];

              return CheckboxListTile(
                title: Text(todo.title),
                onChanged: (_) => actionS.add(ToggleTodo(todo)),
                value: todo.completed,
                secondary: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).accentColor,
                  ),
                  onPressed: () => actionS.add(RemoveTodo(todo)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          actionS.add(
            AddTodo(
              Todo(
                ++_id,
                randomString(10),
                false,
              ),
            ),
          );
        },
      ),
    );
  }
}
```
