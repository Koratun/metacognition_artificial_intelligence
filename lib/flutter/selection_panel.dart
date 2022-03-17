import 'package:flutter/material.dart';

import 'layer_tile.dart';
import 'pycontroller.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var py = PyController.of(context);
    if (!py.initialized) {
      py.init();
    }
  }

  @override
  void dispose() {
    PyController.of(context).dispose();
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
          PyController.of(context)
              .sendMessage("switched to $_selectedCategory");
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
        crossAxisSpacing: 8,
        mainAxisExtent: 100,
      ),
      itemCount: 21,
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

        return LayerTile(
            i, _selectedCategory, _entranceAnimation, _entranceController);
      },
    );

    return LimitedBox(
      maxHeight: MediaQuery.of(context).size.height,
      maxWidth: 128 * 3,
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
