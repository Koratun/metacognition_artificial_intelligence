import 'package:flutter/material.dart';

import 'layer_tile.dart';

class CreationCanvas extends StatefulWidget {
  const CreationCanvas({Key? key}) : super(key: key);

  @override
  State<CreationCanvas> createState() => _CreationCanvasState();
}

class _CreationCanvasState extends State<CreationCanvas>
    with TickerProviderStateMixin, ChangeNotifier {
  final List<LayerTile> tiles = <LayerTile>[];
  final List<Offset> positions = <Offset>[];
  final List<Text> tileScripts = <Text>[];

  void addTile(LayerTile layerTile, Offset pos) {
    final AnimationController _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    final Animation<double> _steadyFall = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeInCirc,
    );

    final Animation<double> _entranceAnimation =
        Tween(begin: 16.0, end: 0.0).animate(_steadyFall);

    _entranceController.forward();

    tiles.add(LayerTile(
      layerTile.i,
      layerTile.title,
      _entranceAnimation,
      _entranceController,
      isGridChild: false,
      changeNotifyCallback: notifyListeners,
    ));
    positions.add(pos);
    tileScripts.add(Text(
      "${layerTile.title} ${layerTile.i}",
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.white,
      ),
    ));
  }

  Iterable<Widget> childList() sync* {
    for (var i = 0; i < tiles.length; i++) {
      yield tiles[i];
      yield tileScripts[i];
    }
  }

  int childCount() => tiles.length * 2;

  @override
  Widget build(BuildContext context) {
    return DragTarget<LayerTile>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          child: CustomMultiChildLayout(
            delegate: CreationCanvasDelegate(
                changeNotifier: this, positions: positions),
            children: [
              for (var i = 0; i < childCount(); i++)
                LayoutId(
                  id: i,
                  child: childList().elementAt(i),
                )
            ],
          ),
          color: Colors.black,
        );
      },
      onAcceptWithDetails: (DragTargetDetails details) =>
          setState(() => addTile(details.data, details.offset)),
    );
  }
}

class CreationCanvasDelegate extends MultiChildLayoutDelegate {
  final List<Offset> positions;

  CreationCanvasDelegate({required changeNotifier, required this.positions})
      : super(relayout: changeNotifier);

  @override
  void performLayout(Size size) {
    for (var i = 0; i < positions.length; i++) {
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
