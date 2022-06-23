import 'package:flutter/material.dart';

class NodeSocket extends StatefulWidget {
  final bool incoming;
  final bool? vertical;
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
    this.vertical,
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

class _NodeSocketState extends State<NodeSocket> {
  late Color targetColor;

  @override
  void initState() {
    super.initState();
    targetColor =
        widget.minNodes > 0 ? _StatusColors.noNodes : widget.backgroundColor;
  }

  @override
  void didUpdateWidget(NodeSocket oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // First determine what color the socket should be
    Color targetColor;
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
  }
}
