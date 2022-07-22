import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'schemas/schema.dart';
import 'schemas/creation_response.dart';
import 'schemas/validation_response.dart';

import 'node_socket.dart';
import 'dialogue_panel.dart';
import 'console.dart';

class LayerTile extends StatefulWidget {
  final int i;
  final String category;
  final String? type;
  final Animation<double> _entranceAnimation;
  final AnimationController _entranceController;
  final void Function()? changeNotifyCallback;
  final ValueNotifier<RequestResponseSchema>? messageHandler;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ui.Image? symbol;

  const LayerTile.gridChild(
    this.i,
    this.category,
    this._entranceAnimation,
    this._entranceController, {
    Key? key,
    this.type,
    this.backgroundColor,
    this.foregroundColor,
    this.symbol,
  })  : changeNotifyCallback = null,
        messageHandler = null,
        super(key: key);

  LayerTile.canvasChild(
    this.i,
    this.category,
    this._entranceAnimation,
    this._entranceController, {
    Key? key,
    this.changeNotifyCallback,
    this.type,
    this.backgroundColor,
    this.foregroundColor,
    this.symbol,
  })  : messageHandler =
            ValueNotifier<RequestResponseSchema>(RequestResponseSchema()),
        super(key: key);

  @override
  State<LayerTile> createState() => LayerTileState();
}

class LayerTileState extends State<LayerTile> with TickerProviderStateMixin {
  late final AnimationController hoverController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late final Animation<double> sizeAnimation = Tween<double>(
    begin: 0.0,
    end: 8.0,
  ).animate(hoverController);

  Map<String, String>? layerSettings;
  int? minUpstreamNodes;
  //This is only a double so we can access the infinity property
  double? maxUpstreamNodes;
  int? minDownstreamNodes;
  //This is only a double so we can access the infinity property
  double? maxDownstreamNodes;
  String? nodeId;

  void _handleMessages() {
    var data = widget.messageHandler!.value;
    var console = Provider.of<ConsoleInterface>(context, listen: false);
    if (data is CreationResponse) {
      setState(() {
        layerSettings = data.layerSettings;
        minUpstreamNodes = data.nodeConnectionLimits.minUpstream;
        minDownstreamNodes = data.nodeConnectionLimits.minDownstream;
        var n = double.tryParse(data.nodeConnectionLimits.maxUpstream);
        if (n == null) {
          maxUpstreamNodes = double.infinity;
        } else {
          maxUpstreamNodes = n;
        }
        n = double.tryParse(data.nodeConnectionLimits.maxDownstream);
        if (n == null) {
          maxDownstreamNodes = double.infinity;
        } else {
          maxDownstreamNodes = n;
        }
        nodeId = data.nodeId;
      });
    } else {
      console.log(
        "WARNING!! Unhandled response: $data from layer message handler: $nodeId",
        Logging.devError,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    widget._entranceController.forward();
    sizeAnimation.addListener(() {
      setState(() {});
    });
    if (!isGridChild) {
      if (widget.changeNotifyCallback != null) {
        sizeAnimation.addListener((() => widget.changeNotifyCallback!()));
        widget._entranceAnimation
            .addListener(() => setState(() => widget.changeNotifyCallback!()));
      }

      // Handle race condition of python finishing initialization of the
      // layer tile before dart
      if (widget.messageHandler!.value.runtimeType != RequestResponseSchema) {
        _handleMessages();
      }
      widget.messageHandler!.addListener(_handleMessages);
    }
  }

  @override
  void didUpdateWidget(LayerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isGridChild) {
      if (oldWidget.category != widget.category) {
        widget._entranceController.forward();
      } else {
        widget._entranceController
            .forward(from: oldWidget._entranceController.value);
      }
    }
  }

  @override
  void dispose() {
    widget._entranceController.dispose();
    hoverController.dispose();
    super.dispose();
  }

  bool get isGridChild => widget.messageHandler == null;

  bool get isPlaceholder => widget.foregroundColor == null;

  Widget makeDraggable(Widget Function({bool hovering}) childFunction) {
    return Draggable<LayerTile>(
      data: widget,
      feedback: LimitedBox(
        child: childFunction(hovering: true),
      ),
      hitTestBehavior: HitTestBehavior.translucent,
      child: childFunction(),
    );
  }

  Widget makeLayerIcon({bool hovering = false}) {
    final double foregroundSize = 64 +
        (hovering
            ? 16
            : (isGridChild
                ? sizeAnimation.value
                : widget._entranceAnimation.value + sizeAnimation.value));

    final layerTilePainter = LayerTilePainter(
      foregroundSize,
      widget.backgroundColor!,
      widget.foregroundColor!,
      widget.type!,
      widget.symbol,
    );

    final Widget layerIcon = MouseRegion(
      onEnter: (event) {
        if (isGridChild || widget._entranceAnimation.isCompleted) {
          if (layerTilePainter.hitTest(event.localPosition)) {
            hoverController.forward();
          }
        }
      },
      onHover: (event) {
        if (isGridChild || widget._entranceAnimation.isCompleted) {
          if (layerTilePainter.hitTest(event.localPosition)) {
            hoverController.forward();
          } else {
            hoverController.reverse();
          }
        }
      },
      onExit: (_) {
        hoverController.reverse();
      },
      child: CustomPaint(
        painter: layerTilePainter,
        child: SizedBox(
          width: layerTilePainter.iconSize.width,
          height: layerTilePainter.iconSize.height,
        ),
      ),
    );

    if (hovering) {
      return Opacity(opacity: 0.45, child: layerIcon);
    } else if (!isGridChild) {
      List<Positioned> sockets = [];
      if (nodeId != null) {
        if (maxUpstreamNodes! > 0) {
          sockets.add(Positioned(
            left: 0,
            top: layerTilePainter.iconSize.height / 2 - 10 + 8,
            child: NodeSocket(
              nodeId!,
              Offset(
                -layerTilePainter.iconSize.width / 2,
                0,
              ),
              true,
              minUpstreamNodes!,
              maxUpstreamNodes!,
              widget.backgroundColor!,
            ),
          ));
          layerTilePainter.clipSocketPosition(SocketDirection.west);
        }
        if (maxDownstreamNodes! > 0) {
          sockets.add(Positioned(
            right: 0,
            top: layerTilePainter.iconSize.height / 2 - 10 + 8,
            child: NodeSocket(
              nodeId!,
              Offset(
                layerTilePainter.iconSize.width / 2,
                0,
              ),
              false,
              minUpstreamNodes!,
              maxUpstreamNodes!,
              widget.backgroundColor!,
            ),
          ));
          layerTilePainter.clipSocketPosition(SocketDirection.east);
        }
      }

      return SizedBox(
        width: layerTilePainter.iconSize.width + 16,
        height: layerTilePainter.iconSize.height + 16,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  child: layerIcon,
                  onTap: nodeId == null
                      ? null
                      : () =>
                          Provider.of<DialogueInterface>(context, listen: false)
                              .displayLayerSettings(this),
                ),
              ),
            ),
            for (var socket in sockets) socket,
          ],
        ),
      );
    }
    return layerIcon;
  }

  Widget placeholderTile({bool hovering = false}) {
    final Widget tile = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        border: Border.all(color: Colors.lightBlueAccent[700]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        Icons.layers,
        size: 64 +
            (hovering
                ? 16
                : (isGridChild
                    ? sizeAnimation.value
                    : widget._entranceAnimation.value + sizeAnimation.value)),
        color: widget.i ~/ 3 < 4 ? Colors.black : Colors.white,
      ),
    );
    if (hovering) {
      return Opacity(opacity: 0.45, child: tile);
    }
    return tile;
  }

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.type ?? "${widget.category} ${widget.i}",
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (isGridChild) {
      return ScaleTransition(
        scale: widget._entranceAnimation,
        child: isPlaceholder
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    onEnter: (event) {
                      hoverController.forward();
                    },
                    onExit: (event) {
                      hoverController.reverse();
                    },
                    child: makeDraggable(placeholderTile),
                  ),
                  title,
                ],
              )
            : makeDraggable(makeLayerIcon),
      );
    } else {
      return LimitedBox(
        child: isPlaceholder
            ? Column(
                children: [
                  MouseRegion(
                    onEnter: (event) {
                      if (widget._entranceAnimation.isCompleted) {
                        hoverController.forward();
                      }
                    },
                    onExit: (event) {
                      hoverController.reverse();
                    },
                    child: placeholderTile(),
                  ),
                  title,
                ],
              )
            : makeLayerIcon(),
      );
    }
  }
}

class LayerTilePainter extends CustomPainter {
  final double foregroundSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final String name;
  final ui.Image? symbol;
  late Path octogonBoundary;
  late final Rect iconSize;
  final List<SocketDirection> socketsToClip = [];

  LayerTilePainter(
    this.foregroundSize,
    this.backgroundColor,
    this.foregroundColor,
    this.name,
    this.symbol,
  ) {
    // Create a path that will form the octogon of the image
    octogonBoundary = Path()
      ..addPolygon([
        const Offset(0, 6),
        Offset(0, 6 * 3 + foregroundSize),
        Offset(6, 6 * 4 + foregroundSize),
        Offset(6 * 3 + foregroundSize, 6 * 4 + foregroundSize),
        Offset(6 * 4 + foregroundSize, 6 * 3 + foregroundSize),
        Offset(6 * 4 + foregroundSize, 6),
        Offset(6 * 3 + foregroundSize, 0),
        const Offset(6, 0),
      ], true);
    iconSize = Offset.zero & octogonBoundary.getBounds().size;
  }

  void clipSocketPosition(SocketDirection dir) {
    socketsToClip.add(dir);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var dir in socketsToClip) {
      Path p = Path()
        ..addRect(Rect.fromCenter(
          center: Offset(size.width / 2 - 2, 0),
          width: 20,
          height: 20,
        ));
      p = p.transform(Matrix4.rotationZ(dir.radians).storage).transform(
          Matrix4.translationValues(size.width / 2, size.height / 2, 0)
              .storage);
      octogonBoundary = Path.combine(
        PathOperation.difference,
        octogonBoundary,
        p,
      );
    }
    canvas.clipPath(octogonBoundary);

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
          colors: [backgroundColor, Color.lerp(backgroundColor, null, 0.5)!],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [18 / (24 + foregroundSize), 1.0]).createShader(iconSize);
    canvas.drawRect(iconSize, backgroundPaint);

    final highlightRect =
        Rect.fromLTWH(6, 6, 12 + foregroundSize, 6 + foregroundSize);
    final highlightPaint = Paint()
      ..shader = LinearGradient(
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, foregroundColor, 0.5)!
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [6 / (6 + foregroundSize), 1.0]).createShader(highlightRect);
    canvas.drawRect(highlightRect, highlightPaint);

    canvas.drawRect(
      Rect.fromLTWH(12, 12, foregroundSize, foregroundSize),
      Paint()..color = foregroundColor,
    );

    // If file hasn't loaded yet, display an ellipses instead of the image
    if (symbol != null) {
      canvas.drawImageRect(
        symbol!,
        Rect.fromLTWH(0, 0, symbol!.width * 1.0, symbol!.height * 1.0),
        Rect.fromCenter(
          center:
              Offset(12 + foregroundSize / 2, 12 + foregroundSize * (3 / 8)),
          width: foregroundSize / 2,
          height: foregroundSize / 2,
        ),
        Paint(),
      );
    } else {
      for (var x = -6; x <= 6; x += 6) {
        canvas.drawCircle(
          Offset(12 + foregroundSize / 2 + x, 12 + foregroundSize / 2),
          2,
          Paint()..color = Colors.black,
        );
      }
    }

    // Display text with Paragraph object
    final layerTitleBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 15,
        fontFamily: "Segoe UI",
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: backgroundColor,
        fontWeight: FontWeight.bold,
      ))
      ..addText(name.toUpperCase());
    final layerTitle = layerTitleBuilder.build()
      ..layout(ui.ParagraphConstraints(width: foregroundSize));
    canvas.drawParagraph(
      layerTitle,
      Offset(12, 12 + foregroundSize - layerTitle.height),
    );
  }

  @override
  bool hitTest(Offset position) => octogonBoundary.contains(position);

  @override
  bool shouldRepaint(LayerTilePainter oldDelegate) {
    return foregroundSize != oldDelegate.foregroundSize ||
        symbol != oldDelegate.symbol;
  }
}
