import 'package:flutter/material.dart';
import 'package:metacognition_artificial_intelligence/flutter/mouse_hugger.dart';

class LayerTile extends StatefulWidget {
  final int _i;
  final String _title;
  final Animation<double> _entranceAnimation;
  final AnimationController _entranceController;

  const LayerTile(
      this._i, this._title, this._entranceAnimation, this._entranceController,
      {Key? key})
      : super(key: key);

  @override
  State<LayerTile> createState() => _LayerTileState();
}

class _LayerTileState extends State<LayerTile> with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    widget._entranceController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Widget _mouseDetector(Widget child) {
    return Listener(
      onPointerDown: (event) => MouseHugger.of(context).setHugger(
          LimitedBox(
            child: _imageTile(hovering: true),
          ),
          event),
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
        color: widget._i ~/ 3 < 4
            ? Colors.grey[100 * (widget._i ~/ 3 + 1)]
            : Colors.grey[100 * (widget._i ~/ 3 + 2)],
        border: Border.all(color: Colors.lightBlueAccent[700]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        Icons.layers,
        size: 64 + (hovering ? 8 : _sizeAnimation.value),
        color: widget._i ~/ 3 < 4 ? Colors.black : Colors.white,
      ),
    );
    if (hovering) {
      return Opacity(opacity: 0.45, child: imageTile);
    }
    return imageTile;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget._entranceAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mouseDetector(_imageTile()),
          Text(
            "${widget._title} ${widget._i}",
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
