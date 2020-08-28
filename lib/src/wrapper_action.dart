import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs, missing_return

@sealed
abstract class ActionType {
  const ActionType.empty();

  static final initial = _Initial();
  static final external = _External();

  factory ActionType.sideEffect(int index) = _SideEffect;

  @override
  String toString() {
    if (this is _Initial) {
      return '⭍';
    }
    if (this is _External) {
      return '↓';
    }
    if (this is _SideEffect) {
      return '⟳${(this as _SideEffect).index}';
    }
  }
}

class _Initial extends ActionType {
  _Initial() : super.empty();
}

class _External extends ActionType {
  _External() : super.empty();
}

class _SideEffect extends ActionType {
  final int index;

  _SideEffect(this.index) : super.empty();
}

class WrapperAction<A> {
  final A action;
  final ActionType type;

  WrapperAction(this.action, this.type);
}
