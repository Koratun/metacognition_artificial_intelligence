import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'pycontroller.dart';
import 'creation_canvas.dart';
import 'schemas/command_type_enum.dart';
import 'schemas/connection.dart';
import 'schemas/success_fail_response.dart';

class NodeSocket extends StatefulWidget {
  final String nodeId;
  final Offset centerPos;
  final bool incoming;
  final bool vertical;
  final int minNodes;
  //This is only a double so we can access the infinity property
  final double maxNodes;
  final Color backgroundColor;

  const NodeSocket(
    this.nodeId,
    this.centerPos,
    this.incoming,
    this.minNodes,
    this.maxNodes,
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
    duration: const Duration(milliseconds: 500),
  );

  late Color targetColor;
  late Color lastColor;
  late Color currentColor;
  late SocketDirection facing;
  int _currentNodes = 0;

  int get currentNodes => _currentNodes;

  set currentNodes(v) {
    if (currentNodes != v) {
      // Save the current color as the last color
      lastColor = currentColor;

      // Determine what color the socket should be
      if (v == 0 && widget.minNodes > 0) {
        targetColor = _StatusColors.noNodes;
      } else if (v == widget.minNodes - 1) {
        targetColor = _StatusColors.oneMoreNode;
      } else if (v == widget.maxNodes) {
        targetColor = _StatusColors.maxNodes;
      } else if (v >= widget.minNodes && v < widget.maxNodes) {
        targetColor = widget.backgroundColor;
      } else {
        targetColor = Color.lerp(
          _StatusColors.noNodes,
          _StatusColors.oneMoreNode,
          v / (widget.minNodes - 1),
        )!;
      }
      colorTransition.forward(from: 0);
      _currentNodes = v;
    }
  }

  @override
  void initState() {
    super.initState();
    targetColor =
        widget.minNodes > 0 ? _StatusColors.noNodes : widget.backgroundColor;
    currentColor = targetColor;
    lastColor = targetColor;
    colorTransition.addListener(() => setState(
          () => currentColor = Color.lerp(
            lastColor,
            targetColor,
            colorTransition.value,
          )!,
        ));
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
    if (currentNodes > 0) {
      if (widget.centerPos != oldWidget.centerPos) {
        if (!widget.incoming) {
          Provider.of<CreationCanvasState>(context)
              .updateStartConnection(widget.nodeId, widget.centerPos);
        } else {
          Provider.of<CreationCanvasState>(context)
              .updateEndConnection(widget.nodeId, widget.centerPos);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    CreationCanvasState canvasStateListen =
        Provider.of<CreationCanvasState>(context);

    Widget thePaint = CustomPaint(
      painter: SocketPainter(currentColor, facing),
      child: const SizedBox(
        width: 20,
        height: 20,
      ),
    );

    if (widget.incoming) {
      thePaint = DragTarget<_NodeSocketState>(
        onAccept: (incomingState) {
          if (widget.incoming) {
            if (currentNodes == widget.maxNodes) {
              canvasStateListen.cancelConnection(incomingState.widget.nodeId);
            } else {
              PyController.request(
                CommandType.connect,
                (response) {
                  if (response is SuccessFailResponse) {
                    if (response.error != null) {
                      canvasStateListen
                          .cancelConnection(incomingState.widget.nodeId);
                    } else {
                      canvasStateListen.connectNodes(
                        incomingState.widget.nodeId,
                        widget.nodeId,
                        widget.centerPos,
                      );
                      currentNodes += 1;
                      incomingState.currentNodes += 1;
                    }
                  }
                },
                data: Connection(incomingState.widget.nodeId, widget.nodeId),
              );
            }
          }
        },
        builder: (context, candidateData, rejectedData) => CustomPaint(
          painter: SocketPainter(currentColor, facing),
          child: const SizedBox(
            width: 20,
            height: 20,
          ),
        ),
      );
    }

    if ((!widget.incoming && currentNodes != widget.maxNodes) ||
        (widget.incoming && currentNodes > 0)) {
      return Draggable<_NodeSocketState>(
        data: this,
        feedback: Container(),
        onDragStarted: () {
          var canvasState =
              Provider.of<CreationCanvasState>(context, listen: false);
          if (!widget.incoming && currentNodes != widget.maxNodes) {
            canvasState.newConnection(
              widget.nodeId,
              widget.centerPos,
            );
          }
        },
        onDragUpdate: (details) {
          canvasStateListen.updateNewConnection(
            widget.nodeId,
            details.globalPosition,
          );
        },
        onDraggableCanceled: (_, __) {
          canvasStateListen.cancelConnection(widget.nodeId);
        },
        onDragCompleted: () {},
        child: thePaint,
      );
    } else {
      return thePaint;
    }
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
