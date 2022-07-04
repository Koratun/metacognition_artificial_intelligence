import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'main.dart';

class NodeConnection extends StatefulWidget {
  Offset start;
  Offset end;

  NodeConnection(this.start, {Key? key})
      : end = start,
        super(key: key);

  T quadrantSwitch<T>({
    required T Function() bottomRight,
    required T Function() bottomLeft,
    required T Function() topLeft,
    required T Function() topRight,
  }) {
    if (start.dx <= end.dx && start.dy <= end.dy) {
      return bottomRight();
    } else if (start.dx >= end.dx && start.dy <= end.dy) {
      return bottomLeft();
    } else if (start.dx >= end.dx && start.dy >= end.dy) {
      return topLeft();
    } else {
      return topRight();
    }
  }

  @override
  State<NodeConnection> createState() => _NodeConnectionState();
}

class _NodeConnectionState extends State<NodeConnection>
    with TickerProviderStateMixin {
  late final AnimationController glow = AnimationController(
    vsync: this,
    upperBound: 2,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    glow.repeat();
    glow.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ConnectionPainter(widget.start, widget.end, glow.value),
      size: Size(
        (widget.start.dx - widget.end.dx).abs() + 6,
        (widget.start.dy - widget.end.dy).abs() + 6,
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  late final double distance;
  late final Path curve;
  late final Rect bounds;
  final double glowTick;

  T quadrantSwitch<T>({
    required T Function() bottomRight,
    required T Function() bottomLeft,
    required T Function() topLeft,
    required T Function() topRight,
  }) {
    if (start.dx <= end.dx && start.dy <= end.dy) {
      return bottomRight();
    } else if (start.dx >= end.dx && start.dy <= end.dy) {
      return bottomLeft();
    } else if (start.dx >= end.dx && start.dy >= end.dy) {
      return topLeft();
    } else {
      return topRight();
    }
  }

  ConnectionPainter(this.start, this.end, this.glowTick) {
    final Offset distanceVector = end - start;
    distance = distanceVector.distance;
    curve = quadrantSwitch(
      bottomRight: () {
        return Path()
          ..moveTo(3, 3)
          ..lineTo(distanceVector.dx + 3, distanceVector.dy + 3);
      },
      bottomLeft: () {
        return Path()
          ..moveTo(-3, 3)
          ..lineTo(-distanceVector.dx - 3, distanceVector.dy + 3)
          ..transform(
              Matrix4.translationValues(distanceVector.dx + 6, 0, 0).storage);
      },
      topLeft: () {
        return Path()
          ..moveTo(-3, -3)
          ..lineTo(-distanceVector.dx - 3, -distanceVector.dy - 3)
          ..transform(Matrix4.translationValues(
                  distanceVector.dx + 6, distanceVector.dy + 6, 0)
              .storage);
      },
      topRight: () {
        return Path()
          ..moveTo(3, -3)
          ..lineTo(distanceVector.dx + 3, -distanceVector.dy - 3)
          ..transform(
              Matrix4.translationValues(0, distanceVector.dy + 6, 0).storage);
      },
    );
    bounds = curve.getBounds().inflate(3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double gradiantAngle = 0;
    if (start.dy == end.dy) {
      if (start.dx <= end.dx) {
        gradiantAngle = 0;
      } else {
        gradiantAngle = math.pi;
      }
    } else if (start.dx == end.dx) {
      if (start.dy < end.dy) {
        gradiantAngle = math.pi / 2;
      } else {
        gradiantAngle = math.pi * 1.5;
      }
    } else {
      gradiantAngle = quadrantSwitch(
        bottomRight: () => math.acos((end.dx - start.dx) / distance),
        bottomLeft: () =>
            math.acos((end.dy - start.dy) / distance) + math.pi / 2,
        topLeft: () =>
            1.5 * math.pi - math.acos((start.dy - end.dy) / distance),
        topRight: () =>
            1.5 * math.pi + math.acos((start.dy - end.dy) / distance),
      );
    }
    canvas.drawPath(
      curve,
      Paint()
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          colors: [mainColors[500]!, mainColors[300]!],
          tileMode: TileMode.mirror,
          transform: GradientRotation(gradiantAngle),
        ).createShader(Rect.fromLTWH(
          glowTick * 18,
          6,
          18,
          6,
        )),
    );
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}
