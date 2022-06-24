import 'package:flutter/material.dart';
import 'dart:math' as math;

class NodeSocket extends StatefulWidget {
  final bool incoming;
  final bool vertical;
  final int minNodes;
  //This is only a double so we can access the infinity property
  final double maxNodes;
  final int currentNodes;
  final Color backgroundColor;

  const NodeSocket(
    this.incoming,
    this.minNodes,
    this.maxNodes,
    this.currentNodes,
    this.backgroundColor, {
    this.vertical = false,
    Key? key,
  }) : super(key: key);

  @override
  State<NodeSocket> createState() => _NodeSocketState();
}

class _StatusColors {
  static Color get noNodes => const Color(0xFFCC0000);
  static Color get oneMoreNode => const Color.fromARGB(255, 255, 196, 0);
  static Color get maxNodes => const Color.fromARGB(255, 76, 255, 41);
}

class _NodeSocketState extends State<NodeSocket> with TickerProviderStateMixin {
  late final AnimationController colorTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late Color targetColor;
  late Color lastColor;
  late Color currentColor;
  late SocketDirection facing;

  @override
  void initState() {
    super.initState();
    targetColor =
        widget.minNodes > 0 ? _StatusColors.noNodes : widget.backgroundColor;
    currentColor = targetColor;
    lastColor = targetColor;
    colorTransition.addListener(() => setState(() => currentColor = Color.lerp(
          lastColor,
          targetColor,
          colorTransition.value,
        )!));
    if (!widget.vertical) {
      if (widget.incoming) {
        facing = SocketDirection.west;
      } else {
        facing = SocketDirection.east;
      }
    } else {
      if (widget.incoming) {
        facing = SocketDirection.north;
      } else {
        facing = SocketDirection.south;
      }
    }
  }

  @override
  void didUpdateWidget(NodeSocket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentNodes != oldWidget.currentNodes) {
      // Save the current color as the last color
      lastColor = currentColor;

      // Determine what color the socket should be
      if (widget.currentNodes == 0 && widget.minNodes > 0) {
        targetColor = _StatusColors.noNodes;
      } else if (widget.currentNodes == widget.minNodes - 1) {
        targetColor = _StatusColors.oneMoreNode;
      } else if (widget.currentNodes == widget.maxNodes) {
        targetColor = _StatusColors.maxNodes;
      } else if (widget.currentNodes >= widget.minNodes &&
          widget.currentNodes < widget.maxNodes) {
        targetColor = widget.backgroundColor;
      } else {
        targetColor = Color.lerp(
          _StatusColors.noNodes,
          _StatusColors.oneMoreNode,
          widget.currentNodes / (widget.minNodes - 1),
        )!;
      }
      colorTransition.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SocketPainter(currentColor, facing),
      child: const SizedBox(
        width: 20,
        height: 20,
      ),
    );
  }
}

enum SocketDirection { east, south, west, north }

extension SocketDirectionExt on SocketDirection {
  int get angle {
    switch (this) {
      case SocketDirection.east:
        return 0;
      case SocketDirection.south:
        return 90;
      case SocketDirection.west:
        return 180;
      case SocketDirection.north:
        return 270;
    }
  }

  double get radians => angle * math.pi / 180;
}

class SocketPainter extends CustomPainter {
  final Color color;
  final SocketDirection facing;

  SocketPainter(this.color, this.facing);

  @override
  void paint(Canvas canvas, Size size) {
    Path boundary = Path()
      ..addPolygon([
        Offset.zero,
        Offset(size.width - 4, 0),
        Offset(size.width, 4),
        const Offset(4, 4),
        Offset(4, size.height - 4),
        Offset(size.width, size.height - 4),
        Offset(size.width - 4, size.height),
        Offset(0, size.height),
      ], true);
    final toOrigin =
        Matrix4.translationValues(-size.width / 2, -size.height / 2, 0);
    boundary = boundary
        .transform(toOrigin.storage)
        .transform(Matrix4.rotationZ(facing.radians).storage)
        .transform(Matrix4.inverted(toOrigin).storage);
    canvas.drawPath(
      boundary,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant SocketPainter oldDelegate) =>
      color != oldDelegate.color;
}
