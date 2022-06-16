import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FloatingWidgetLayoutDelegate extends SingleChildLayoutDelegate {
  FloatingWidgetLayoutDelegate({required this.position});

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints.tightForFinite();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      position.translate(childSize.width / -2, childSize.height / -2);

  @override
  bool shouldRelayout(FloatingWidgetLayoutDelegate oldDelegate) =>
      oldDelegate.position != position;
}
