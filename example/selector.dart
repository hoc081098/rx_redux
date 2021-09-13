import 'package:built_collection/built_collection.dart';
import 'package:disposebag/disposebag.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart_ext/state_stream.dart';

//
// [BEGIN] STATE
//

class Book {
  final String id;
  final String userId;
  final String name;

  Book(this.id, this.userId, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ name.hashCode;

  @override
  String toString() => 'Book{id: $id, userId: $userId, name: $name}';
}

class User {
  final String id;
  final String name;

  User(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'User{id: $id, name: $name}';
}

class State {
  final User? selectedUser;
  final BuiltList<Book> allBooks;
  final Object? error;

  State(this.selectedUser, this.allBooks, this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is State &&
          runtimeType == other.runtimeType &&
          selectedUser == other.selectedUser &&
          allBooks == other.allBooks &&
          error == other.error;

  @override
  int get hashCode =>
      selectedUser.hashCode ^ allBooks.hashCode ^ error.hashCode;

  @override
  String toString() =>
      'State{selectedUser: $selectedUser, allBooks: $allBooks, error: $error}';
}

//
// [END] STATE
//

//
// [BEGIN] ACTION
//

abstract class Action {}

class ChangeSelectedUserAction implements Action {
  final User? user;

  ChangeSelectedUserAction(this.user);
}

class AddBookAction implements Action {
  final Book book;

  AddBookAction(this.book);
}

class ErrorAction implements Action {
  final Object error;

  ErrorAction(this.error);
}

//
// [END] ACTION
//

//
// [BEGIN] DEMO
//

State reducer(State state, Action action) {
  if (action is ChangeSelectedUserAction) {
    return State(
      action.user,
      state.allBooks,
      state.error,
    );
  }
  if (action is AddBookAction) {
    return State(
      state.selectedUser,
      state.allBooks.rebuild((b) => b.add(action.book)),
      state.error,
    );
  }
  if (action is ErrorAction) {
    return State(
      state.selectedUser,
      state.allBooks,
      action.error,
    );
  }

  return state;
}

void main() async {
  final bag = DisposeBag();
  final store = RxReduxStore<Action, State>(
      initialState: State(null, <Book>[].build(), null),
      sideEffects: [],
      reducer: reducer);

  // select 2 pieces of state and combine them.
  final select2$ = store.select2(
    (s) => s.selectedUser?.id,
    (s) => s.allBooks,
    (String? userId, BuiltList<Book> books) {
      print('<> Call projector with userId=$userId and books=${books.length}');

      return userId != null && books.isNotEmpty
          ? books.where((b) => b.userId == userId).toBuiltList()
          : books;
    },
  );
  final visibleBooks$ = select2$
      .shareState(select2$.value); // TODO: remove select2$ and shareState

  // logging state.
  print('~> ${visibleBooks$.value}');
  unawaited(
    visibleBooks$.listen((s) => print('1 ~> $s')).disposedBy(bag),
  );
  Future<void>.delayed(
    const Duration(milliseconds: 500),
    () => visibleBooks$.listen((s) => print('2 ~> $s')).disposedBy(bag),
  );

  // dispatch actions.
  [
    ChangeSelectedUserAction(User('0', 'Petrus')),
    AddBookAction(Book('0', '0', 'Book 0')),
    AddBookAction(Book('1', '0', 'Book 1')),
    AddBookAction(Book('2', '0', 'Book 2')),
    AddBookAction(Book('3', '0', 'Book 3')),
  ].forEach(store.dispatch);
  await Future<void>.delayed(const Duration(seconds: 1));
  print('---------------------------------------------------');

  [
    ErrorAction('Error 1') /* has no effect */,
    ChangeSelectedUserAction(
        User('0', 'Hoc')) /* same user id -> has no effect */,
    ChangeSelectedUserAction(
        User('0', 'Nguyen')) /* same user id -> has no effect */,
    ChangeSelectedUserAction(User('1', 'Hello')),
    ErrorAction('Error 2') /* has no effect */,
    AddBookAction(Book('4', '1', 'Book 4')),
    ChangeSelectedUserAction(User('0', 'Rx redux 1')),
    ChangeSelectedUserAction(
        User('0', 'Rx redux 2')) /* same user id -> has no effect */,
    ErrorAction('Error 3') /* has no effect */,
  ].forEach(store.dispatch);
  await Future<void>.delayed(const Duration(seconds: 1));
  print('---------------------------------------------------');

  // end by disposing store.
  await bag.dispose();
  await store.dispose();
}

//
// [END] DEMO
//
