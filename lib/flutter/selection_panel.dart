import 'package:flutter/material.dart';
import 'window_style_dropdown_menu.dart';
import 'layer_tile.dart';
import 'main.dart';
import 'pycontroller.dart';
import 'schemas/command_enum.dart';
import 'schemas/startup_response.dart';

const categoryNames = <String>[
  "Tutorials",
  "Datasources and Manipulation",
  "Core",
  "Compilation",
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
  final GlobalKey<PopupMenuButtonState<int>> _key = GlobalKey();

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

  Widget buttonDropdown(String title, List<List<String>> dropdownItems) {
    return WindowStyleDropdownMenu(
      dropdownWidth: 278,
      buttonTitle: title,
      dropdownItems: [
        for (List<String> dropdown in dropdownItems)
          ListTile(
            mouseCursor: SystemMouseCursors.click,
            trailing:
                Text(dropdown[0], style: const TextStyle(color: Colors.white)),
            title: Text(
              dropdown[1],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              debugPrint(dropdown[2]);
            },
          )
      ],
    );
  }

//drop down menu
  @override
  Widget build(BuildContext context) {
    final toolbar = Container(
      color: const Color.fromARGB(255, 14, 14, 14),
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
              ['Ctrl + T', 'Tools', "Tools selected"],
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
