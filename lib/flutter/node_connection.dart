import 'package:flutter/material.dart';

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

  ConnectionPainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => false;
}
