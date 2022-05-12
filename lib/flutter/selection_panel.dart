import 'package:flutter/material.dart';

import 'layer_tile.dart';
import 'main.dart';
import 'pycontroller.dart';
import 'schemas/command_enum.dart';
import 'schemas/startup_response.dart';

const categoryNames = <String>[
  "Tutorials",
  "Core",
  "Preprocessing",
  "Convolutional",
  "Recurrent",
];

class SelectionPanel extends StatefulWidget {
  const SelectionPanel({Key? key}) : super(key: key);

  @override
  State<SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<SelectionPanel>
    with TickerProviderStateMixin {
  String _selectedCategory = categoryNames[0];

  Map<String, List<String>>? _categoryList;

  @override
  void initState() {
    super.initState();
    PyController.init().then((_) {
      PyController.request(
        Command.startup,
        (response) {
          if (response is StartupResponse) {
            setState(
              () => _categoryList = response.categoryList.map(
                (key, value) {
                  return MapEntry(
                    key
                        .split(RegExp(r"(?=[A-Z])"))
                        .map((e) => e[0].toUpperCase() + e.substring(1))
                        .join(" "),
                    value,
                  );
                },
              ),
            );
          }
        },
      );
    });
  }

  @override
  void dispose() {
    PyController.dispose();
    super.dispose();
  }

  Widget _buildLayerCategory(String title) {
    return Material(
      color: _selectedCategory == title
          ? Colors.lightBlue[200]
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = title;
          });
          print(title);
        },
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.bodyText1,
          ),
          onPressed: null,
          child: const Text("File"),
        ),
        VerticalDivider(
          width: 20,
          thickness: 1,
          color: Colors.grey[700],
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.bodyText1,
          ),
          onPressed: null,
          child: const Text("Settings"),
        ),
      ],
    );

    final categories = Column(
      mainAxisSize: MainAxisSize.min,
      children: categoryNames.map((e) => _buildLayerCategory(e)).toList(),
    );

    final ScrollController scrollController = ScrollController();

    final layerTiles = GridView.builder(
      controller: scrollController,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 100,
      ),
      itemCount: _categoryList == null
          ? 21
          : _categoryList![_selectedCategory] == null
              ? 21
              : _categoryList![_selectedCategory]!.length,
      itemBuilder: (BuildContext context, int i) {
        const _entranceTime = 500;
        final _millesecondsToWait = i * 100;

        final AnimationController _entranceController = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _millesecondsToWait + _entranceTime),
        );

        final Animation<double> _entranceAnimation = CurvedAnimation(
          parent: _entranceController,
          curve: DramaticEntrance(_millesecondsToWait / _entranceTime),
        );

        _entranceController.forward();

        return Center(
          child: LayerTile(
            i,
            _selectedCategory,
            _entranceAnimation,
            _entranceController,
            isGridChild: true,
            layerName: _categoryList == null
                ? null
                : _categoryList![_selectedCategory] == null
                    ? null
                    : _categoryList![_selectedCategory]![i],
          ),
        );
      },
    );

    return LimitedBox(
      maxHeight: MediaQuery.of(context).size.height,
      maxWidth: Main.getSidePanelWidth(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          toolbar,
          categories,
          Expanded(
            child: layerTiles,
          ),
        ],
      ),
    );
  }
}

class DramaticEntrance extends Curve {
  final double _percentToWait;

  const DramaticEntrance(this._percentToWait);

  @override
  double transform(double t) {
    if (t < _percentToWait / (1 + _percentToWait)) {
      return 0;
    }
    t -= _percentToWait / (1 + _percentToWait);
    t /= 1 - _percentToWait / (1 + _percentToWait);
    return t * t * -2 + 3 * t; //-2t^2 + 3t
  }
}
