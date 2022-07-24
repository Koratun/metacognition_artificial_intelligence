import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'schemas/command_type_enum.dart';
import 'schemas/connection.dart';
import 'schemas/success_fail_response.dart';
import 'schemas/graph_exception_response.dart';

import 'console.dart';
import 'pycontroller.dart';
import 'layer_tile.dart';
import 'creation_canvas.dart';

class NodeSocket extends StatefulWidget {
  final LayerTileState parentLayer;
  late final String nodeId;
  final Offset centerPos;
  final bool incoming;
  final bool vertical;
  late final int minNodes;
  //This is only a double so we can access the infinity property
  late final double maxNodes;
  late final Color backgroundColor;

  NodeSocket(
    this.parentLayer,
    this.centerPos,
    this.incoming, {
    this.vertical = false,
    Key? key,
  }) : super(key: key) {
    nodeId = parentLayer.nodeId!;
    backgroundColor = parentLayer.widget.backgroundColor!;
    if (incoming) {
      minNodes = parentLayer.minUpstreamNodes!;
      maxNodes = parentLayer.maxUpstreamNodes!;
    } else {
      minNodes = parentLayer.minDownstreamNodes!;
      maxNodes = parentLayer.maxDownstreamNodes!;
    }
  }

  @override
  State<NodeSocket> createState() => _NodeSocketState();
}

class _StatusColors {
  static Color get noNodes => const Color(0xFFCC0000);
  static Color get oneMoreNode => const Color.fromARGB(255, 255, 196, 0);
  static Color get nodesSatisfied => const Color.fromARGB(255, 76, 255, 41);
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
        // If max nodes are reached, make this socket blend in with its node.
        targetColor = widget.backgroundColor;
      } else if (v >= widget.minNodes && v < widget.maxNodes) {
        targetColor = _StatusColors.nodesSatisfied;
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
    targetColor = widget.minNodes > 0
        ? _StatusColors.noNodes
        : _StatusColors.nodesSatisfied;
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
          Provider.of<CreationCanvasInterface>(context)
              .updateStartConnection(widget.nodeId, widget.centerPos);
        } else {
          Provider.of<CreationCanvasInterface>(context)
              .updateEndConnection(widget.nodeId, widget.centerPos);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var interfaceListen = Provider.of<CreationCanvasInterface>(context);

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
            var console = Provider.of<ConsoleInterface>(context, listen: false);
            if (currentNodes == widget.maxNodes) {
              interfaceListen.cancelConnection(incomingState.widget.nodeId);
              console.log(
                "This node has already reached its maximum number of "
                "incoming connections",
                Logging.error,
              );
            } else {
              PyController.request(
                CommandType.connect,
                (response) {
                  if (response is SuccessFailResponse) {
                    if (response.error != null) {
                      interfaceListen
                          .cancelConnection(incomingState.widget.nodeId);
                      console.log(response.error!, Logging.error);
                    } else {
                      interfaceListen.connectNodes(
                        incomingState.widget.nodeId,
                        widget.nodeId,
                        widget.centerPos,
                      );
                      currentNodes += 1;
                      incomingState.currentNodes += 1;
                      console.log(
                        "Successfully connected "
                        "${incomingState.widget.parentLayer.widget.type} to "
                        "${widget.parentLayer.widget.type}",
                        Logging.info,
                      );
                    }
                  } else if (response is GraphExceptionResponse) {
                    interfaceListen
                        .cancelConnection(incomingState.widget.nodeId);
                    console.log(response.error, Logging.error);
                  } else {
                    console.log(
                      "WARNING!! Unhandled response: $response from incoming "
                      "Node Socket on ${widget.nodeId}",
                      Logging.devError,
                    );
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
          var interface =
              Provider.of<CreationCanvasInterface>(context, listen: false);
          if (!widget.incoming && currentNodes != widget.maxNodes) {
            interface.newConnection(
              widget.nodeId,
              widget.centerPos,
            );
          }
        },
        onDragUpdate: (details) {
          interfaceListen.updateNewConnection(
            widget.nodeId,
            details.globalPosition,
          );
        },
        onDraggableCanceled: (_, __) {
          interfaceListen.cancelConnection(widget.nodeId);
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
