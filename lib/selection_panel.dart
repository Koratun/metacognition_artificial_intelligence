import 'package:flutter/material.dart';
import 'package:boxy/flex.dart';

const categoryNames = <String>[
  "Tutorials",
  "Core",
  "Preprocessing",
  "Convolutional",
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
          crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 24),
      itemCount: 21,
      itemBuilder: (BuildContext context, int i) {
        // TODO: Placeholder code for when we have an actual list of layers
        return Container(
          decoration: BoxDecoration(
            color: i ~/ 3 < 4
                ? Colors.grey[100 * (i ~/ 3 + 1)]
                : Colors.grey[100 * (i ~/ 3 + 2)],
            border: Border.all(color: Colors.lightBlueAccent[700]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              "$_selectedCategory $i",
              style: TextStyle(
                  fontSize: 16.0,
                  color: i ~/ 3 < 4 ? Colors.black : Colors.white),
            ),
          ),
        );
      },
    );

    return Container(
      padding: EdgeInsets.all(5),
      child: LimitedBox(
        maxHeight: MediaQuery.of(context).size.height,
        maxWidth: 96 * 3,
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
      ),
    );
  }
}
