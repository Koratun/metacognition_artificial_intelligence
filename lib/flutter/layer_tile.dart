import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as im;
import 'schemas/node_connection_limits.dart';

import 'schemas/creation_response.dart';
import 'schemas/schema.dart';

class LayerTile extends StatefulWidget {
  final int i;
  final String title;
  final String? layerName;
  final Animation<double> _entranceAnimation;
  final AnimationController _entranceController;
  final void Function()? changeNotifyCallback;
  final ValueNotifier<Schema?>? messageHandler;
  final Color? foregroundColor;

  const LayerTile(
    this.i,
    this.title,
    this._entranceAnimation,
    this._entranceController, {
    Key? key,
    this.changeNotifyCallback,
    this.layerName,
    this.messageHandler,
    this.foregroundColor,
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

  late final List<String>? layerSettings;
  late final NodeConnectionLimits? nodeConnectionLimits;
  late final String? nodeId;

  late final ui.Image? symbol;

  Future<ui.Image> loadRawImage() async {
    ByteData data = await rootBundle
        .load('assets/layer_tiles/' + widget.layerName! + '.png');
    var image = im.decodePng(data.buffer.asUint8List());
    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image!.getBytes());
    ui.ImageDescriptor id = ui.ImageDescriptor.raw(
      buffer,
      height: image.height,
      width: image.width,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  @override
  void initState() {
    super.initState();
    if (widget.layerName != null) {
      loadRawImage().then((value) => setState(() => symbol = value));
    }
    sizeAnimation.addListener(() {
      setState(() {});
    });
    if (!isGridChild) {
      if (widget.changeNotifyCallback != null) {
        sizeAnimation.addListener((() => widget.changeNotifyCallback!()));
        widget._entranceAnimation
            .addListener(() => setState(() => widget.changeNotifyCallback!()));
      }
      widget.messageHandler!.addListener(() {
        var data = widget.messageHandler!.value;
        if (data is CreationResponse) {
          setState(() {
            layerSettings = data.layerSettings;
            nodeConnectionLimits = data.nodeConnectionLimits;
            nodeId = data.nodeId;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget._entranceController.dispose();
    hoverController.dispose();
    super.dispose();
  }

  bool get isGridChild => widget.messageHandler == null;

  Widget makeDraggable(Widget child) {
    return Draggable<LayerTile>(
      data: widget,
      feedback: LimitedBox(
        child: imageTile(hovering: true),
      ),
      hitTestBehavior: HitTestBehavior.translucent,
      child: MouseRegion(
        onEnter: (event) {
          hoverController.forward();
        },
        onExit: (event) {
          hoverController.reverse();
        },
        child: child,
      ),
    );
  }

  Widget makeLayerIcon({bool hovering = false}) {
    final double foregroundSize = hovering
        ? 16
        : (isGridChild
            ? sizeAnimation.value
            : widget._entranceAnimation.value + sizeAnimation.value);

    Widget layerIcon = CustomPaint(
      painter: LayerTilePainter(
        foregroundSize,
        const Color(0xff044862),
        widget.foregroundColor!,
        symbol,
      ),
    );

    if (hovering) {
      return Opacity(opacity: 0.45, child: layerIcon);
    }
    return layerIcon;
  }

  Widget imageTile({bool hovering = false}) {
    final Widget imageTile = Container(
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
      return Opacity(opacity: 0.45, child: imageTile);
    }
    return imageTile;
  }

  @override
  Widget build(BuildContext context) {
    final title = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.layerName ?? "${widget.title} ${widget.i}",
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            makeDraggable(imageTile()),
            title,
          ],
        ),
      );
    } else {
      return LimitedBox(
        child: Column(
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
              child: imageTile(),
            ),
            title,
          ],
        ),
      );
    }
  }
}

class LayerTilePainter extends CustomPainter {
  final double imageSize;
  final Color backgroundColor;
  final Color iconColor;
  final ui.Image? symbol;
  late final Path octogonBoundary;

  LayerTilePainter(
    this.imageSize,
    this.backgroundColor,
    this.iconColor,
    this.symbol,
  ) {
    // Create a path that will form the octogon of the image
    octogonBoundary = Path()
      ..moveTo(0, 6)
      ..addPolygon([
        Offset(0, 6 * 3 + imageSize),
        Offset(6, 6 * 4 + imageSize),
        Offset(6 * 3 + imageSize, 6 * 4 + imageSize),
        Offset(6 * 4 + imageSize, 6 * 3 + imageSize),
        Offset(6 * 4 + imageSize, 6),
        Offset(6 * 3 + imageSize, 0),
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
          stops: [18 / (24 + imageSize), 1.0]).createShader(widgetSize);
    canvas.drawRect(widgetSize, backgroundPaint);

    final highlightRect = Rect.fromLTWH(6, 6, 12 + imageSize, 6 + imageSize);
    final highlightPaint = Paint()
      ..shader = LinearGradient(
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, iconColor, 0.5)!
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [6 / (6 + imageSize), 1.0]).createShader(highlightRect);
    canvas.drawRect(highlightRect, highlightPaint);

    final iconForegroundPaint = Paint()..color = iconColor;
    canvas.drawRect(
      Rect.fromLTWH(12, 12, imageSize, imageSize),
      iconForegroundPaint,
    );

    if (symbol != null) {
      canvas.drawImage(
        symbol!,
        Offset(12 + imageSize / 2 - 14, (3 / 40) * imageSize + 12),
        Paint(),
      );
    }

    // Display text with Paragraph object
  }

  @override
  bool shouldRepaint(LayerTilePainter oldDelegate) {
    return imageSize != oldDelegate.imageSize;
  }
}
