# rx_redux

[![Build Status](https://travis-ci.org/hoc081098/rx_redux.svg?branch=master)](https://travis-ci.org/hoc081098/rx_redux)
[![Pub](https://img.shields.io/pub/v/rx_redux.svg)](https://pub.dartlang.org/packages/rx_redux)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

-   Reactive redux store for `Dart` & `Flutter` inspired by **[RxRedux-freeletics](https://github.com/freeletics/RxRedux)**
-   A Redux store implementation entirely based on Dart `Stream`, with the power of `RxDart` (inspired by [redux-observable](https://redux-observable.js.org)) 
that helps to isolate side effects. RxRedux is (kind of) a replacement for RxDart's `.scan()` operator. 

<p float="left">
  <img src="https://raw.githubusercontent.com/freeletics/RxRedux/master/docs/rxredux.png" width="512" alt="RxRedux In a Nutshell"/> 
  <img src="https://github.com/hoc081098/rx_redux/blob/v2/logo.png?raw=true" />
</p>


## Get started

```yaml
dependencies:
  rx_redux: ^2.0.0
```

## How is this different from other Redux implementations
In contrast to any other Redux inspired library out there, this library is pure backed on top of Dart Stream.
This library offers a custom stream transformer `ReduxStoreStreamTransformer` (or extension method `reduxStore`) and treats upstream events as `Actions`. 

# Redux Store
A Store is basically an stream container for state. 
This library offers a custom stream transformer `ReduxStoreStreamTransformer` (or extension method `reduxStore`) to create such a state container.
It takes an `initialState` and a list of `SideEffect<State, Action>` and a `Reducer<State, Action>`

# Action
An Action is a command to "do something" in the store. 
An `Action` can be triggered by the user of your app (i.e. UI interaction like clicking a button) but also a `SideEffect` can trigger actions.
Every Action goes through the reducer. 
If an `Action` is not changing the state at all by the `Reducer` (because it's handled as a side effect), just return the previous state.
Furthermore, `SideEffects` can be registered for a certain type of `Action`.

# Reducer
A `Reducer` is basically a function `(State, Action) -> State` that takes the current State and an Action to compute a new State.
Every `Action` goes through the state reducer.
If an `Action` is not changing the state at all by the `Reducer` (because it's handled as a side effect), just return the previous state.

# Side Effect
A Side Effect is a function of type `(Stream<Action>, GetState<State>) -> Stream<Action>`.
**So basically it's Actions in and Actions out.** 
You can think of a `SideEffect` as a use case in clean architecture: It should do just one job.
Every `SideEffect` can trigger multiple `Actions` (remember it returns `Stream<Action>`) which go through the `Reducer` but can also trigger other `SideEffects` registered for the corresponding `Action`.
An `Action` can also have a `payload`. For example, if you load some data from backend, you emit the loaded data as an `Action` like `class DataLoadedAction { final Foo data; }`. 
The mantra an Action is a command to do something is still true: in that case it means data is loaded, do with it "something".

# GetState
Whenever a `SideEffect` needs to know the current State it can use `GetState` to grab the latest state from Redux Store. `GetState` is basically just a function `() -> State` to grab the latest State anytime you need it.

# Usage
Let's create a simple Redux Store for Pagination: Goal is to display a list of `Persons` on screen.
**For a complete example check [the sample application incl. README](example/README.md)**
but for the sake of simplicity let's stick with this simple "list of persons example":

```dart
class State {
  final int currentPage;
  final List<Person> persons; // The list of persons 
  final bool loadingNextPage;
  final errorLoadingNextPage;
  // constructor
  // hashCode and ==
  // copyWith
}

final initialState = State(
  currentPage: 0, 
  persons: [], 
  loadingNextPage: false, 
  errorLoadingNextPage: null,
);
```

```dart
abstract class Action { }

// Action to load the first page. Triggered by the user.
class LoadNextPageAction implements Action {
  const LoadNextPageAction();
}

// Persons has been loaded
class PageLoadedAction implements Action {
  final List<Person> personsLoaded;
  final int page;
  // constructor
}

// Started loading the list of persons
class LoadPageAction implements Action {
  const LoadPageAction();
}

// An error occurred while loading
class ErrorLoadingNextPageAction implements Action {
  final error;
  // constructor
}
```

```dart
// SideEffect is just a type alias for such a function:
Stream<State> loadNextPageSideEffect (
  Stream<Action> actions,
  GetState<State> state,
) =>
  actions
    // This side effect only runs for actions of type LoadNextPageAction
    .whereType<LoadNextPageAction>()
    .switchMap((_) {
      // do network request
      final State currentState = state();
      final int nextPage = state.currentPage + 1;
      
      return backend
        .getPersons(nextPage)
        .map<Action>((List<Person> person) {
          return PageLoadedAction(
            personsLoaded: persons, 
            page: nextPage
          );
        })
        .onErrorReturnWith((error) => ErrorLoadingNextPageAction(error))
        .startWith(const LoadPageAction());
    });
```

```dart
// Reducer is just a type alias for a function
State reducer(State state, Action action) {
  if (action is LoadPageAction) {
    return state.copyWith(loadingNextPage: true);
  }
  if (action is ErrorLoadingNextPageAction) {
    return state.copy(
      loadingNextPage: false,
      errorLoadingNextPage: action.error,
    );
  }
  if (action is PageLoadedAction) {
    return state.copy(
      loadingNextPage: false, 
      errorLoadingNextPage: null
      persons: [...state.persons, ...action.persons],
      page: action.page,
    );
  }

  // Reducer is actually not handling this action (a SideEffect does it)
  return state;
}
```

```dart
final Stream<Action> actions = ...;
final List<SideEffect<State, Action> sideEffects = [loadNextPageSideEffect, ...];

actions.transform(
  ReduxStoreStreamTransformer<Action, State>(
    initialStateSupplier: () => initialState,
    sideEffects: sideEffects,
    reducer: reducer,
  ),
).listen(view.render);
```

or using extension method `reduxStore`:

```dart
actions.reduxStore(
  initialStateSupplier: () => initialState,
  sideEffects: sideEffects,
  reducer: reducer,
).listen(view.render);
```

The [following video](https://youtu.be/M7lx9Y9ANYo) (click on it) illustrates the workflow:

[![RxRedux explanation](https://i.ytimg.com/vi/M7lx9Y9ANYo/hqdefault.jpg?sqp=-oaymwEXCNACELwBSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLAqwunKP2_qGE0HYUlquWkFccM5MA)](https://youtu.be/M7lx9Y9ANYo)


0. Let's take a look at the following illustration:
The blue box is the `View` (think UI). 
The `Presenter` or `ViewModel` has not been drawn for the sake of readability but you can think of having such additional layers between View and Redux State Machine.
The yellow box represents a `Store`. 
The grey box is the `reducer`. 
The pink box is a `SideEffect`
Additionally, a green circle represents `State` and a red circle represents an `Action` (see next step).
On the right you see a UI mock of a mobile app to illustrate UI changes.

1. `NextPageAction` gets triggered from the UI (by scrolling at the end of the list). Every `Action` goes through the `reducer` and all `SideEffects` registered for this type of Action.

2. `Reducer` is not interested in `NextPageAction`. So while `NextPageAction` goes through the reducer, it doesn't change the state.

3. `loadNextPageSideEffect` (pink box), however, cares about `NextPageAction`. This is the trigger to run the side-effect.

4. So `loadNextPageSideEffect` takes `NextPageAction` and starts doing the job and makes the http request to load the next page from backend. Before doing that, this side effect starts with emitting `LoadPageAction`.

5. `Reducer` takes `LoadPageAction` emitted from the side effect and reacts on it by "reducing the state". 
This means `Reducer` knows how to react on `LoadPageAction` to compute the new state (showing progress indicator at the bottom of the list).
Please note that the state has changed (highlighted in green) which also results in changing the UI (progress indicator at the end of the list).

6. Once `loadNextPageSideEffect` gets the result back from backend, the side effect emits a new `PageLoadedAction`.
This Action contains a "payload" - the loaded data.

```dart
class PageLoadedAction implements Action {
  final List<Person> personsLoaded;
  final int page;
}
```

7. As any other Action `PageLoadedAction` goes through the `Reducer`. The Reducer processes this Action and computes a new state out of it by appending the loaded data to the already existing data (progress bar also is hidden).

Final remark:
This system allows you to create a plugin in system of `SideEffects` that are highly reusable and specific to do a single use case.

<p align="center">
  <img src="https://raw.githubusercontent.com/freeletics/RxRedux/master/docs/step13.png" width="640" alt="Step12" />
</p>

Also `SideEffects` can be invoked by `Actions` from other `SideEffects`.


**For a complete example check [the sample application incl. README](https://github.com/freeletics/RxRedux/master/sample)**

# FAQ

## I get a `StackOverflowError`
This is a common pitfall and is most of the time caused by the fact that a `SideEffect` emits an `Action` as output that it also consumes from upstream leading to an infinite loop.

```dart

final SideEffect<State, Int> sideEffect = (actions, state) => actions.map((i) => i * 2);

final inputActions = Stream.value(1);

inputActions.reduxStore(
  initialStateSupplier: () => 'InitialState',
  sideEffects: [sideEffect],
  reducer: (state, action) => newState,
);
```

The problem is that from upstream we get `Int 1`.
But since `SideEffect` reacts on that action `Int 1` too, it computes `1 * 2` and emits `2`, which then again gets handled by the same SideEffect ` 2 * 2 = 4` and emits `4`, which then again gets handled by the same SideEffect `4 * 2 = 8` and emits `8`, which then getst handled by the same SideEffect and so on (endless loop) ...

## Who processes an `Action` first: `Reducer` or `SideEffect`?

Since every Action runs through both `Reducer` and registered `SideEffects` this is a valid question.
Technically speaking `Reducer` gets every `Action` from upstream before the registered `SideEffects`.
The idea behind this is that a `Reducer` may have already changed the state before a `SideEffect` start processing the Action.

For example let's assume upstream only emits exactly one Action (because then it's simpler to illustrate the sequence of workflow):

```dart
// 1. upstream emits events
final upstreamActions = Stream.value(SomeAction());

SideEffect<State, Action> sideEffect1 = (actions, state) {
  // 3. Runs because of SomeAction
  return actions.where((a) => a is SomeAction).mapTo(OtherAction());
};

SideEffect<State, Action> sideEffect2 = (actions, state) {
  // 5. Runs because of OtherAction
  return actions.where((a) => a is OtherAction).mapTo(YetAnotherAction());
};

upstreamActions.reduxStore(
  initialStateSupplier: () => initialState,
  sideEffects: [sideEffect1, sideEffect2],
  reducer: (state, action) {
    // 2. This runs first because of SomeAction
    ...
    // 4. This runs again because of OtherAction (emitted by SideEffect1)
    ...
    // 6. This runs again because of YetAnotherAction emitted from SideEffect2)
  }
).listen(print);
```

So the workflow is as follows:
1. Upstream emits `SomeAction`
2. `reducer` processes `SomeAction`
3. `SideEffect1` reacts on `SomeAction` and emits `OtherAction` as output
4. `reducer` processes `OtherAction`
5. `SideEffect2` reacts on `OtherAction` and emits `YetAnotherAction`
6. `reducer` processes `YetAnotherAction`

## Can I use `variable` and `function` for `SideEffects` or `Reducer`?

Absolutely. `SideEffect` is just a type alias for a function `typedef Stream<A> SideEffect<S, A>(Stream<A> actions, GetState<S> state);`.

In `Dart` you can use a lambda for that like this:
```dart
SideEffect<State, Action> sideEffect1 = (actions, state) {
  return actions
      .where((a) => a is SomeAction)
      .mapTo(OtherAction());
};
```

of write a function (instead of a lambda):

```dart
Stream<Action> sideEffect2(
  Stream<Action> actions,
  GetState<State> state,
) {
  return actions
      .where((a) => a is SomeAction)
      .mapTo(OtherAction());
}
```

Both are totally equal and can be used like that:

```dart
upstreamActions.reduxStore(
  initialStateSupplier: () => initialState,
  sideEffects: [sideEffect1, sideEffect2],
  reducer: (state, action) => newState,
).listen(...);
```

The same is valid for Reducer. Reducer is just a type alias for a function `typedef S Reducer<S, A>(S currentState, A newAction);`
You can define your reducer as lambda or function:

```dart
final reducer = (State state, Action action) => /*return new state*/;

// or

State reducer(State state, Action action) {
  // return new state
}
```

## Is `distinct` (More commonly known as `distinctUntilChanged` in other Rx implementations) considered as best practice?
Yes it is because `reduxStore(...)` is not taking care of only emitting state that has been changed
compared to previous state.
Therefore, `.distinct()` is considered as best practice.
```dart
actions
  .reduxStore( ... )
  .distinct()
  .listen(view.render);
```

## What if I would like to have a SideEffect that returns no Action?

For example, let's say you just store something in a database but you don't need a Action as result
piped backed to your redux store. In that case you can simple use `Stream.empty()` like this:

```dart
Stream<Action> saveToDatabaseSideEffect(Stream<Action> actions, GetState<State> getState) {
    return actions.flatMap((_) async* {
      await saveToDb(something);
      // not emit any Action
    });
}
```

## How do I cancel ongoing `SideEffects` if a certain `Action` happens?

Let's assume you have a simple `SideEffect` that is triggered by `Action1`. 
Whenever `Action2` is emitted our `SideEffect` should stop. 
In `RxDart` this is quite easy to do by using: `.takeUntil()`

```dart
mySideEffect(Stream<Action> actions, GetState<State> getState) => 
    actions
        .whereType<Action1>()
        .flatMap((_) => doSomething())
        .takeUntil(actions.whereType<Action2>()); // Once Action2 triggers the whole SideEffect gets canceled.
```

## Do I need an Action to start observing data?
Let's say you would like to start observing a database right from the start inside your Store.
This sounds pretty much like as soon as you have subscribers to your Store and therefore you don't need a dedicated Action to start observing the database.

```dart
Stream<Action> observeDatabaseSideEffect(Stream<Action> _, GetState<State> __) =>
    database // please notice that we don't use Stream<Action> at all
        .queryItems()
        .map((items) => DatabaseLoadedAction(items));
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/rx_redux/issues
