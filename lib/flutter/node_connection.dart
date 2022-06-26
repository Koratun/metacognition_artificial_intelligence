import 'package:flutter/material.dart';

import 'main.dart';

class NodeConnection extends StatefulWidget {
  final Offset start;
  final Offset end;

  const NodeConnection(this.start, this.end, {Key? key}) : super(key: key);

  @override
  State<NodeConnection> createState() => _NodeConnectionState();
}

class _NodeConnectionState extends State<NodeConnection>
    with TickerProviderStateMixin {
  late final AnimationController glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(NodeConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {}
}

class ConnectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  late final Path curve;
  late final Rect bounds;

  ConnectionPainter(this.start, this.end) {
    curve = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    bounds = curve.getBounds();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        curve,
        Paint()
          ..shader = LinearGradient(
            colors: [mainColors[400]!, mainColors[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            tileMode: TileMode.mirror,
          ).createShader(Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width / 10,
            bounds.height / 10,
          )));
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => false;
}
