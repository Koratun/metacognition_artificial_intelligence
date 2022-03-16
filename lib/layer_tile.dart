import 'package:flutter/material.dart';

class LayerTile extends StatefulWidget {
  final int _i;
  final String _title;

  const LayerTile(this._i, this._title, {Key? key}) : super(key: key);

  @override
  State<LayerTile> createState() => _LayerTileState();
}

class _LayerTileState extends State<LayerTile> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late final Animation<double> _sizeAnimation = Tween<double>(
    begin: 0.0,
    end: 8.0,
  ).animate(_controller);

  @override
  void initState() {
    super.initState();
    _sizeAnimation.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _mouseDetector(Widget child) {
    return GestureDetector(
      onTap: () {
        print("Tapped");
      },
      child: MouseRegion(
        onEnter: (event) {
          _controller.forward();
        },
        onExit: (event) {
          _controller.reverse();
        },
        // onHover: (event) {
        //   print("Hover");
        // },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: LimitedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mouseDetector(Container(
              decoration: BoxDecoration(
                color: widget._i ~/ 3 < 4
                    ? Colors.grey[100 * (widget._i ~/ 3 + 1)]
                    : Colors.grey[100 * (widget._i ~/ 3 + 2)],
                border: Border.all(color: Colors.lightBlueAccent[700]!),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.layers,
                size: 64 + _sizeAnimation.value,
                color: widget._i ~/ 3 < 4 ? Colors.black : Colors.white,
              ),
            )),
            Text(
              "${widget._title} ${widget._i}",
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
