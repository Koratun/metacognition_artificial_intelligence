import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as im;
import 'dart:io';
import 'dart:convert';

import 'schemas/event_type_enum.dart';
import 'schemas/initialize_layers_event.dart';

import 'window_style_dropdown_menu.dart';
import 'console.dart';
import 'layer_tile.dart';
import 'dialogue_panel.dart';
import 'tutorial_data.dart';
import 'tutorial.dart';
import 'main.dart';
import 'pycontroller.dart';

const categoryNames = <String>[
  "Tutorials",
  "Datasources And Preprocessing",
  "Core",
  "Compilation",
  "Convolutional",
  "Recurrent",
];

const categoryColors = {
  "Core": Color(0xff044862),
  "Datasources And Preprocessing": Color.fromARGB(255, 4, 98, 9),
  "Compilation": Color.fromARGB(255, 58, 6, 126),
};

Map<String, Map<String, dynamic>> layerTileAssetData = {
  "Input": {"color": const Color(0xff72efdd)},
  "Dense": {"color": const Color(0xff9ad1d4)},
  "Output": {"color": const Color(0xff4ea8de)},
  "OneHotEncode": {"color": const Color.fromARGB(255, 129, 167, 146)},
  "MapRange": {"color": const Color.fromARGB(255, 108, 175, 164)},
  "Boston Housing": {"color": const Color(0xfffdff91)},
  "MNIST": {"color": const Color(0xffe5d9a5)},
  "Fashion MNIST": {"color": const Color.fromARGB(255, 156, 0, 0)},
  "CIFAR10": {"color": const Color(0xff29b947)},
  "CIFAR100": {"color": const Color(0xff0098e7)},
  "IMDB": {"color": const Color(0xffe4e400)},
  "Compile": {"color": const Color(0xff6ab0e6)},
  "CategoricalAccuracy": {"color": const Color(0xfffff08c)},
  "BinaryCrossentropy": {"color": const Color.fromARGB(255, 255, 205, 41)},
  "RMSProp": {"color": const Color(0xff3360ff)},
  "Adagrad": {"color": const Color(0xff3afecc)},
  "Ftrl": {"color": const Color(0xff00d539)},
  "Poisson": {"color": const Color(0xff92ff13)},
  "LogCoshError": {"color": const Color(0xffffc313)},
  "MeanSquaredError": {"color": const Color.fromARGB(255, 255, 217, 0)},
  "CategoricalCrossentropy": {"color": const Color(0xffd67725)},
  "NumpyFlatten": {"color": const Color(0xffc5feff)},
};

const Map<String, String> layerShortenedTitles = {
  "OneHotEncode": "OneHot",
  "MapRange": "Map",
  "Boston Housing": "Boston",
  "Fashion MNIST": "Fashion",
  "BinaryCrossentropy": "Binary",
  "LogCoshError": "LogCosh",
  "MeanSquaredError": "MeanError",
  "CategoricalCrossentropy": "Category",
  "NumpyFlatten": "Flatten",
  "CategoricalAccuracy": "CatAccuracy",
};

class SelectionPanel extends StatefulWidget {
  const SelectionPanel({Key? key}) : super(key: key);

  @override
  State<SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<SelectionPanel>
    with TickerProviderStateMixin {
  String _selectedCategory = categoryNames[0];

  Map<String, List<String>>? _categoryList;
  final Map<TutorialData, bool> tutorialData = {};

  Future<ui.Image> loadRawImage(String layerName) async {
    ByteData data =
        await rootBundle.load('assets/layer_tiles/' + layerName + '.png');
    var image = im.decodePng(data.buffer.asUint8List());
    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image!.getBytes());
    ui.ImageDescriptor id = ui.ImageDescriptor.raw(
      buffer,
      height: image.height,
      width: image.width,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  Future<List<TutorialData>> loadTutorials() async {
    return await Directory("assets/tutorials")
        .list()
        .skipWhile((element) => !element.path.endsWith(".json"))
        .map((d) => d.path.substring(d.path.lastIndexOf(RegExp(r'\\|/')) + 1))
        .asyncMap((f) async =>
            json.decode(await rootBundle.loadString("assets/tutorials/$f")))
        .map((j) => TutorialData.fromJson(j))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    loadTutorials().then((tuts) => setState(
        () => tutorialData.addEntries(tuts.map((e) => MapEntry(e, false)))));
    for (var layerName in layerTileAssetData.keys) {
      loadRawImage(layerName).then((value) =>
          setState(() => layerTileAssetData[layerName]!["symbol"] = value));
    }
    PyController.registerEventHandler(
      EventType.initializeLayers,
      (response) {
        if (response is InitializeLayersEvent) {
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
        } else {
          Provider.of<ConsoleInterface>(context, listen: false).log(
            "WARNING!! Unhandled response: $response from init layers event",
            Logging.devError,
          );
        }
      },
    );
  }

  Widget _buildLayerCategory(String title) {
    return Material(
      color: _selectedCategory == title
          ? Theme.of(context).primaryColor
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

  Widget buttonDropdown(String title, List<List<Object>> dropdownItems) {
    return WindowStyleDropdownMenu(
      dropdownWidth: 278,
      buttonTitle: title,
      dropdownItems: [
        for (List<Object> dropdown in dropdownItems)
          ListTile(
            mouseCursor: SystemMouseCursors.click,
            trailing: Text(dropdown[0] as String,
                style: const TextStyle(color: Colors.white)),
            title: Text(
              dropdown[1] as String,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              debugPrint(dropdown[2] as String);
              if (dropdown.length > 3) {
                (dropdown[3] as Function)();
              }
            },
          )
      ],
    );
  }

//drop down menu
  @override
  Widget build(BuildContext context) {
    final toolbar = Container(
      color: Theme.of(context).backgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buttonDropdown(
            'File',
            [
              ['Ctrl + N', 'New', "New file selected"],
              ['Ctrl + O', 'Open', "Open file selected"],
            ],
          ),
          Container(
            width: 2,
            height: 20,
            color: Colors.grey.shade300,
          ),
          buttonDropdown(
            'Save',
            [
              ['Ctrl + S', 'Save', "Save file selected"],
              ['Ctrl + K + S', 'Save All', "Save all selected"],
            ],
          ),
          Container(
            width: 2,
            height: 20,
            color: Colors.grey.shade300,
          ),
          buttonDropdown(
            'Settings',
            [
              ['Ctrl + E', 'Extensions', "Extensions selected"],
              [
                'Ctrl + Shift + E',
                'Editor Settings',
                "Editor settings selected"
              ],
            ],
          ),
          Container(
            width: 2,
            height: 20,
            color: Colors.grey.shade300,
          ),
          buttonDropdown(
            'Other',
            [
              [
                'Ctrl + R',
                'Reset Backend',
                'Resetting!',
                () {
                  PyController.reset();
                  return null;
                }
              ],
              [
                'Ctrl + Shift + P',
                'Command Palette',
                "Command palette selected"
              ],
            ],
          ),
        ],
      ),
    );

    final categories = Column(
      mainAxisSize: MainAxisSize.min,
      children: categoryNames.map((e) => _buildLayerCategory(e)).toList(),
    );

    Widget selectableTiles;

    if (_selectedCategory == categoryNames[0]) {
      selectableTiles = Consumer<DialogueInterface>(
        builder: (context, interface, child) => Material(
          child: ListView(
            children: [
              for (var d in tutorialData.keys)
                Tutorial(
                  true,
                  d,
                  selected: interface.tutorial == null
                      ? d.shortId == "mai"
                      : interface.tutorial!.data.shortId == d.shortId,
                  completed: tutorialData[d]!,
                  completedCallback: () =>
                      setState(() => tutorialData[d] = true),
                )
            ],
          ),
        ),
      );
    } else {
      final ScrollController scrollController = ScrollController();

      selectableTiles = GridView.builder(
        controller: scrollController,
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
            duration:
                Duration(milliseconds: _millesecondsToWait + _entranceTime),
          );

          final Animation<double> _entranceAnimation = CurvedAnimation(
            parent: _entranceController,
            curve: DramaticEntrance(_millesecondsToWait / _entranceTime),
          );

          final String? name = _categoryList == null
              ? null
              : _categoryList![_selectedCategory] == null
                  ? null
                  : _categoryList![_selectedCategory]![i];

          return Center(
            child: LayerTile.gridChild(
              i,
              _selectedCategory,
              _entranceAnimation,
              _entranceController,
              backgroundColor: categoryColors[_selectedCategory],
              foregroundColor: layerTileAssetData[name]?['color'],
              symbol: layerTileAssetData[name]?['symbol'],
              type: name,
            ),
          );
        },
      );
    }

    return LimitedBox(
      maxHeight: MediaQuery.of(context).size.height,
      maxWidth: Main.getSidePanelWidth(context),
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.ltr,
          children: [
            toolbar,
            categories,
            Expanded(
              child: selectableTiles,
            ),
          ],
        ),
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
