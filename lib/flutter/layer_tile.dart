import 'package:flutter/material.dart';

class LayerTile extends StatefulWidget {
  final int i;
  final String title;
  final Animation<double> _entranceAnimation;
  final AnimationController _entranceController;
  final bool isGridChild;
  final void Function()? changeNotifyCallback;

  const LayerTile(
      this.i, this.title, this._entranceAnimation, this._entranceController,
      {Key? key, required this.isGridChild, this.changeNotifyCallback})
      : super(key: key);

  @override
  State<LayerTile> createState() => LayerTileState();
}

class LayerTileState extends State<LayerTile> with TickerProviderStateMixin {
  late final AnimationController _hoverController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late final Animation<double> _sizeAnimation = Tween<double>(
    begin: 0.0,
    end: 8.0,
  ).animate(_hoverController);

  @override
  void initState() {
    super.initState();
    _sizeAnimation.addListener(() {
      setState(() {});
    });
    if (!widget.isGridChild) {
      _hoverController.forward(from: 1.0);
      if (widget.changeNotifyCallback != null) {
        _sizeAnimation.addListener((() => widget.changeNotifyCallback!()));
        widget._entranceAnimation
            .addListener(() => setState(() => widget.changeNotifyCallback!()));
      }
    }
  }

  @override
  void dispose() {
    widget._entranceController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Widget _mouseDetector(Widget child) {
    return Draggable<LayerTile>(
      data: widget,
      feedback: LimitedBox(
        child: _imageTile(hovering: true),
      ),
      hitTestBehavior: HitTestBehavior.translucent,
      // dragAnchorStrategy: DragAnchorStrategy,
      child: MouseRegion(
        onEnter: (event) {
          _hoverController.forward();
        },
        onExit: (event) {
          _hoverController.reverse();
        },
        child: child,
      ),
    );
  }

  Widget _imageTile({bool hovering = false}) {
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
                : (widget.isGridChild
                    ? _sizeAnimation.value
                    : widget._entranceAnimation.value + _sizeAnimation.value)),
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
    if (widget.isGridChild) {
      return ScaleTransition(
        scale: widget._entranceAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mouseDetector(_imageTile()),
            Text(
              "${widget.title} ${widget.i}",
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      return LimitedBox(
        child: MouseRegion(
          onEnter: (event) {
            _hoverController.forward();
          },
          onExit: (event) {
            _hoverController.reverse();
          },
          child: _imageTile(),
        ),
      );
    }
  }
}
