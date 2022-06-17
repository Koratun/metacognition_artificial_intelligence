import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'schemas/node_connection_limits.dart';

import 'schemas/creation_response.dart';
import 'schemas/schema.dart';

class LayerTile extends StatefulWidget {
  final int i;
  final String category;
  final String? name;
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
    this.name,
    this.backgroundColor,
    this.foregroundColor,
    this.symbol,
  })  : changeNotifyCallback = null,
        messageHandler = null,
        super(key: key);

  const LayerTile.canvasChild(
    this.i,
    this.category,
    this._entranceAnimation,
    this._entranceController, {
    Key? key,
    this.changeNotifyCallback,
    this.name,
    required this.messageHandler,
    this.backgroundColor,
    this.foregroundColor,
    this.symbol,
  }) : super(key: key);

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
  late final NodeConnectionLimits? nodeConnectionLimits;
  late final String? nodeId;

  void _handleMessages() {
    var data = widget.messageHandler!.value;
    if (data is CreationResponse) {
      setState(() {
        layerSettings = data.layerSettings;
        nodeConnectionLimits = data.nodeConnectionLimits;
        nodeId = data.nodeId;
      });
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
      widget.name!,
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
          width: layerTilePainter.octogonBoundary.getBounds().width,
          height: layerTilePainter.octogonBoundary.getBounds().height,
        ),
      ),
    );

    if (hovering) {
      return Opacity(opacity: 0.45, child: layerIcon);
    }
    return layerIcon;
  }

  Widget placeholderTile({bool hovering = false}) {
    final Widget tile = Container(
      decoration: BoxDecoration(
        color: widget.i ~/ 3 < 4
            ? Colors.grey[100 * (widget.i ~/ 3 + 1)]
            : Colors.grey[100 * (widget.i ~/ 3 + 2)],
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
        widget.name ?? "${widget.category} ${widget.i}",
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
  late final Path octogonBoundary;

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
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect widgetSize = octogonBoundary.getBounds();
    canvas.clipPath(octogonBoundary);

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
          colors: [backgroundColor, Color.lerp(backgroundColor, null, 0.5)!],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [18 / (24 + foregroundSize), 1.0]).createShader(widgetSize);
    canvas.drawRect(widgetSize, backgroundPaint);

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
