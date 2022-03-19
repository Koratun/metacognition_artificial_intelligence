import 'package:flutter/material.dart';

class MouseHugger extends InheritedWidget {
  final void Function(Widget hugger, PointerDownEvent event) huggerChange;

  const MouseHugger(
      {Key? key, required Widget child, required this.huggerChange})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(MouseHugger oldWidget) => false;

  static MouseHugger of(BuildContext context) {
    final MouseHugger? result =
        context.dependOnInheritedWidgetOfExactType<MouseHugger>();
    assert(result != null, "MouseHugger not found.");
    return result!;
  }

  void setHugger(Widget hugger, PointerDownEvent event) =>
      huggerChange(hugger, event);
}
