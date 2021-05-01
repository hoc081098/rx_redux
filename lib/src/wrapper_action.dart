import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs

@sealed
abstract class ActionType {
  const ActionType._empty();

  static const _initial = _Initial();
  static const _external = _External();

  static final _sideEffects = <int, _SideEffect>{};

  factory ActionType._sideEffect(int index) =>
      _sideEffects.putIfAbsent(index, () => _SideEffect(index));

  @override
  String toString() {
    if (this is _Initial) {
      return '↯';
    }
    if (this is _External) {
      return '↓';
    }
    return '⟳${(this as _SideEffect).index}';
  }
}

class _Initial extends ActionType {
  const _Initial() : super._empty();
}

class _External extends ActionType {
  const _External() : super._empty();
}

class _SideEffect extends ActionType {
  final int index;

  _SideEffect(this.index) : super._empty();
}

class WrapperAction {
  final Object? _action;
  final ActionType type;

  const WrapperAction._(this._action, this.type);

  factory WrapperAction.external(Object? action) =>
      WrapperAction._(action, ActionType._external);

  factory WrapperAction.sideEffect(Object? action, int index) =>
      WrapperAction._(action, ActionType._sideEffect(index));

  static const initial = WrapperAction._(null, ActionType._initial);

  A action<A>() {
    if (identical(this, initial)) {
      throw StateError('Cannot get action from WrapperAction.initial');
    }
    return _action as A;
  }
}
