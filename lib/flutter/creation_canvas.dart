import 'package:flutter/material.dart';

import 'layer_tile.dart';

class CreationCanvasDelegate extends MultiChildLayoutDelegate {
  final List<LayerTile> tiles = <LayerTile>[];
  final List<Offset> positions = <Offset>[];
  final List<Text> tileScripts = <Text>[];
  final TickerProvider _ticker;
  final CreationCanvasNotifier _changeNotifier;

  CreationCanvasDelegate(this._ticker, this._changeNotifier)
      : super(relayout: _changeNotifier);

  void addTile(LayerTile layerTile, Offset pos) {
    final AnimationController _entranceController = AnimationController(
      vsync: _ticker,
      duration: const Duration(seconds: 2),
    );

    final Animation<double> _steadyFall = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeInCirc,
    );

    final Animation<double> _entranceAnimation =
        Tween(begin: 8.0, end: 0.0).animate(_steadyFall);

    _entranceController.forward();

    tiles.add(LayerTile(
      layerTile.i,
      layerTile.title,
      _entranceAnimation,
      _entranceController,
      isGridChild: false,
      notifier: _changeNotifier,
    ));
    positions.add(pos);
    tileScripts.add(Text(
      "${layerTile.title} ${layerTile.i}",
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.white,
      ),
    ));
    _changeNotifier.notify();
  }

  Iterable<Widget> childList() sync* {
    for (var i = 0; i < tiles.length; i++) {
      yield tiles[i];
      yield tileScripts[i];
    }
  }

  int childCount() => tiles.length * 2;

  @override
  void performLayout(Size size) {
    for (var i = 0; i < tiles.length; i++) {
      var tileID = i * 2;
      var textID = i * 2 + 1;
      Size tileSize = Size.zero;
      if (hasChild(tileID)) {
        tileSize = layoutChild(tileID, const BoxConstraints.tightForFinite());
        positionChild(tileID,
            positions[i].translate(tileSize.width / -2, tileSize.height / -2));
      }
      if (hasChild(textID)) {
        Size textSize = layoutChild(textID, BoxConstraints.loose(size));
        positionChild(
            textID,
            positions[i]
                .translate(textSize.width / -2, tileSize.height / 2 + 8));
      }
    }
  }

  @override
  bool shouldRelayout(CreationCanvasDelegate oldDelegate) {
    print("Canvas relayout?");
    if (positions.length != oldDelegate.positions.length) {
      return true;
    }
    for (var i = 0; i < positions.length; i++) {
      if (positions[i] != oldDelegate.positions[i]) {
        return true;
      }
    }
    return false;
  }
}

class CreationCanvasNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
