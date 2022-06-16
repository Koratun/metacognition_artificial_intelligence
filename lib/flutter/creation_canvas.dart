import 'package:flutter/material.dart';

import 'selection_panel.dart';
import 'layer_tile.dart';
import 'pycontroller.dart';
import 'schemas/command_type_enum.dart';
import 'schemas/create_layer.dart';
import 'schemas/schema.dart';

class CreationCanvas extends StatefulWidget {
  const CreationCanvas({Key? key}) : super(key: key);

  @override
  State<CreationCanvas> createState() => _CreationCanvasState();
}

class _CreationCanvasState extends State<CreationCanvas>
    with TickerProviderStateMixin, ChangeNotifier {
  final List<LayerTile> tiles = <LayerTile>[];
  final List<Offset> positions = <Offset>[];

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

    LayerTile newTile = LayerTile.canvasChild(
      layerTile.i,
      layerTile.title,
      _entranceAnimation,
      _entranceController,
      changeNotifyCallback: notifyListeners,
      backgroundColor: categoryColors[layerTile.title],
      foregroundColor: layerTileAssetData[layerTile.layerName]?['color'],
      symbol: layerTileAssetData[layerTile.layerName]?['symbol'],
      layerName: layerTile.layerName,
      messageHandler:
          ValueNotifier<RequestResponseSchema>(RequestResponseSchema()),
    );
    tiles.add(newTile);
    positions.add(pos);
    if (newTile.layerName != null) {
      PyController.request(
        CommandType.create,
        (response) => newTile.messageHandler!.value = response,
        data: CreateLayer(newTile.layerName!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<LayerTile>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          child: CustomMultiChildLayout(
            delegate: CreationCanvasDelegate(
                changeNotifier: this, positions: positions),
            children: [
              for (var i = 0; i < tiles.length; i++)
                LayoutId(
                  id: i,
                  child: tiles[i],
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
    for (var tileID = 0; tileID < positions.length; tileID++) {
      Size tileSize = Size.zero;
      if (hasChild(tileID)) {
        tileSize = layoutChild(tileID, const BoxConstraints.tightForFinite());
        positionChild(
            tileID,
            positions[tileID]
                .translate(tileSize.width / -2, tileSize.height / -2));
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
