import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'selection_panel.dart';
import 'layer_tile.dart';
import 'node_connection.dart';
import 'pycontroller.dart';

import 'schemas/command_type_enum.dart';
import 'schemas/create_layer.dart';
import 'schemas/creation_response.dart';

class CreationCanvas extends StatelessWidget {
  const CreationCanvas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CreationCanvasState>(
      builder: (context, canvasState, child) {
        return DragTarget<LayerTile>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              color: Theme.of(context).canvasColor,
              child: CustomMultiChildLayout(
                delegate: CreationCanvasDelegate(
                  changeNotifier: canvasState,
                  positions: canvasState.positions,
                  conns: canvasState.conns,
                ),
                children: [
                  for (var pair in canvasState.conns.entries)
                    LayoutId(
                      id: pair.key,
                      child: pair.value,
                    ),
                  for (var pair in canvasState.tiles.entries)
                    LayoutId(
                      id: pair.key,
                      child: pair.value,
                    )
                ],
              ),
            );
          },
          onAcceptWithDetails: (DragTargetDetails details) =>
              canvasState.addTile(details.data, details.offset),
        );
      },
    );
  }
}

class CreationCanvasState extends ChangeNotifier {
  final TickerProvider _ticker;
  final Map<String, LayerTile> tiles = {};
  final Map<String, Offset> positions = {};
  final Map<String, NodeConnection> conns = {};

  CreationCanvasState(this._ticker);

  void addTile(LayerTile layerTile, Offset pos) {
    final AnimationController entranceController = AnimationController(
      vsync: _ticker,
      duration: const Duration(seconds: 1),
    );

    final Animation<double> steadyFall = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeInCirc,
    );

    final Animation<double> entranceAnimation =
        Tween(begin: 16.0, end: 0.0).animate(steadyFall);

    entranceController.forward();

    LayerTile newTile = LayerTile.canvasChild(
      layerTile.i,
      layerTile.category,
      entranceAnimation,
      entranceController,
      changeNotifyCallback: notifyListeners,
      backgroundColor: categoryColors[layerTile.category],
      foregroundColor: layerTileAssetData[layerTile.name]?['color'],
      symbol: layerTileAssetData[layerTile.name]?['symbol'],
      name: layerTile.name,
    );
    if (newTile.name != null) {
      PyController.request(
        CommandType.create,
        (response) {
          if (response is CreationResponse) {
            String id = response.nodeId;
            tiles[id] = newTile;
            positions[id] = pos;
            newTile.messageHandler!.value = response;
            notifyListeners();
          }
        },
        data: CreateLayer(newTile.name!),
      );
    }
  }

  void newConnection(String nodeId, Offset pos) {
    conns[nodeId + ":"] = NodeConnection(pos + positions[nodeId]!);
  }

  void updateNewConnection(String startId, Offset endPos) {
    conns[startId + ":"]?.end = endPos;
    notifyListeners();
  }

  void updateStartConnection(String startId, Offset startPos) {
    for (var pair
        in conns.entries.where((e) => e.key.split(':').first == startId)) {
      pair.value.start = startPos + positions[startId]!;
    }
  }

  void updateEndConnection(String endId, Offset endPos) {
    for (var pair
        in conns.entries.where((e) => e.key.split(':').last == endId)) {
      pair.value.end = endPos + positions[endId]!;
    }
  }

  void cancelConnection(String id) {
    conns.remove(id + ":");
    notifyListeners();
  }

  void connectNodes(String startId, String endId, Offset endPos) {
    conns[startId + ":" + endId] = conns.remove(startId + ":")!
      ..end = endPos + positions[endId]!;
    notifyListeners();
  }
}

class CreationCanvasDelegate extends MultiChildLayoutDelegate {
  final Map<String, Offset> positions;
  final Map<String, NodeConnection> conns;

  CreationCanvasDelegate({
    required Listenable changeNotifier,
    required this.positions,
    required this.conns,
  }) : super(relayout: changeNotifier);

  @override
  void performLayout(Size size) {
    for (var pair in conns.entries) {
      if (hasChild(pair.key)) {
        layoutChild(pair.key, const BoxConstraints.tightForFinite());
        Offset pos = pair.value.quadrantSwitch(
          bottomRight: () => pair.value.start.translate(-3, -3),
          bottomLeft: () => Offset(
            pair.value.end.dx - 3,
            pair.value.start.dy - 3,
          ),
          topLeft: () => pair.value.end.translate(-3, -3),
          topRight: () => Offset(
            pair.value.start.dx - 3,
            pair.value.end.dy - 3,
          ),
        );
        positionChild(pair.key, pos);
      }
    }
    for (var pair in positions.entries) {
      Size tileSize = Size.zero;
      if (hasChild(pair.key)) {
        tileSize = layoutChild(pair.key, const BoxConstraints.tightForFinite());
        positionChild(
          pair.key,
          pair.value.translate(tileSize.width / -2, tileSize.height / -2),
        );
      }
    }
  }

  @override
  bool shouldRelayout(CreationCanvasDelegate oldDelegate) {
    if (positions.length != oldDelegate.positions.length) {
      return true;
    }
    for (var pair in positions.entries) {
      if (pair.value != oldDelegate.positions[pair.key]) {
        return true;
      }
    }
    return false;
  }
}
