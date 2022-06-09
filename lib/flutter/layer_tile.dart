import 'package:flutter/material.dart';
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

  const LayerTile(
      this.i, this.title, this._entranceAnimation, this._entranceController,
      {Key? key,
      this.changeNotifyCallback,
      this.layerName,
      this.messageHandler})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();
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
        dynamic data = widget.messageHandler!.value;
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
