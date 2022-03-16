import 'package:flutter/material.dart';

import 'layer_tile.dart';

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

class _SelectionPanelState extends State<SelectionPanel> {
  String _selectedCategory = categoryNames[0];

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
        crossAxisSpacing: 8,
        mainAxisExtent: 100,
      ),
      itemCount: 21,
      itemBuilder: (BuildContext context, int i) {
        return LayerTile(i, _selectedCategory);
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
