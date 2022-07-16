import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'schemas/dtype_enum.dart';
import 'schemas/command_type_enum.dart';
import 'schemas/update_layer.dart';
import 'schemas/graph_exception_response.dart';
import 'schemas/validation_response.dart';

import 'layer_tile.dart';
import 'pycontroller.dart';
import 'main.dart';

class DialoguePanel extends StatefulWidget {
  const DialoguePanel({Key? key}) : super(key: key);

  @override
  State<DialoguePanel> createState() => _DialoguePanelState();
}

class _DialoguePanelState extends State<DialoguePanel> {
  final _controllers = <String, TextEditingController>{};
  final _widgetErrors = <String, String?>{};

  void pyUpdate(
    String fieldName,
    LayerTileState layerState,
    String v,
  ) {
    layerState.layerSettings![fieldName] = v;
    PyController.request(
      CommandType.update,
      (response) {
        if (response is GraphExceptionResponse) {
          debugPrint(
              "$fieldName setting is incorrect for this layer type: ${layerState.nodeId}");
        } else if (response is ValidationResponse) {
          Map<String, String> errors = {};
          if (response.errors != null) {
            errors = Map.fromEntries(
              response.errors!.map((e) => MapEntry(e.loc.last, e.msg)),
            );
          }
          setState(() {
            for (var field in _widgetErrors.keys) {
              _widgetErrors[field] = errors[field];
            }
          });
        } else {
          debugPrint(
              "WARNING!! Unhandled response: $response from $fieldName setting widget");
        }
      },
      data: UpdateLayer(layerState.nodeId!, {fieldName: v}),
    );
  }

  Widget _plainTextSetting(
      String fieldName, String label, LayerTileState layerState, String v) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] = TextEditingController(text: v);
    }
    if (!_widgetErrors.containsKey(fieldName)) {
      _widgetErrors[fieldName] = null;
    }
    return TextField(
      controller: _controllers[fieldName],
      style: Theme.of(context).textTheme.bodyText2!.copyWith(
            color: Colors.white,
          ),
      decoration: InputDecoration(
        label: Text(
          label,
          style: Theme.of(context).textTheme.bodyText2!.copyWith(
                color: Colors.grey,
              ),
        ),
        border: const OutlineInputBorder(),
        errorText: _widgetErrors[fieldName],
      ),
      onChanged: (v) => pyUpdate(fieldName, layerState, v),
    );
  }

  late final _settingWidgets = <
      String,
      Widget Function(
    LayerTileState,
    String,
  )>{
    "name": (layerState, v) =>
        _plainTextSetting("name", "Variable Name", layerState, v),
    "shape": (layerState, v) =>
        _plainTextSetting("shape", "Shape", layerState, v),
    "old_range_min": (layerState, v) =>
        _plainTextSetting("old_range_min", "Old range minimum", layerState, v),
    "old_range_max": (layerState, v) =>
        _plainTextSetting("old_range_max", "Old range maximum", layerState, v),
    "new_range_min": (layerState, v) =>
        _plainTextSetting("new_range_min", "New range minimum", layerState, v),
    "new_range_max": (layerState, v) =>
        _plainTextSetting("new_range_max", "New range maximum", layerState, v),
    "units": (layerState, v) {
      String fieldName = "units";
      if (!_controllers.containsKey(fieldName)) {
        _controllers[fieldName] = TextEditingController(text: v);
      }
      if (!_widgetErrors.containsKey(fieldName)) {
        _widgetErrors[fieldName] = null;
      }
      return TextField(
        controller: _controllers[fieldName],
        style: Theme.of(context).textTheme.bodyText2!.copyWith(
              color: Colors.white,
            ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          label: Text(
            "Units",
            style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: Colors.grey,
                ),
          ),
          border: const OutlineInputBorder(),
          errorText: _widgetErrors[fieldName],
        ),
        onChanged: (v) => pyUpdate(fieldName, layerState, v),
      );
    },
    "n_classes": (layerState, v) {
      String fieldName = "n_classes";
      if (!_controllers.containsKey(fieldName)) {
        _controllers[fieldName] = TextEditingController(text: v);
      }
      if (!_widgetErrors.containsKey(fieldName)) {
        _widgetErrors[fieldName] = null;
      }
      return TextField(
        controller: _controllers[fieldName],
        style: Theme.of(context).textTheme.bodyText2!.copyWith(
              color: Colors.white,
            ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          label: Text(
            "Number of classifications",
            style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: Colors.grey,
                ),
          ),
          border: const OutlineInputBorder(),
          errorText: _widgetErrors[fieldName],
        ),
        onChanged: (v) => pyUpdate(fieldName, layerState, v),
      );
    },
    "dtype": (layerState, v) {
      String fieldName = "dtype";
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              "Data Type",
              style: Theme.of(context).textTheme.bodyText2!.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          DropdownButton<String>(
            value: "",
            items: [
              DropdownMenuItem(
                value: "",
                child: Text(
                  "Dynamic",
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
              for (var t in Dtype.values)
                DropdownMenuItem(
                  value: t.name,
                  child: Text(
                    t.name,
                    style: Theme.of(context).textTheme.bodyText2!.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
            ],
            onChanged: (v) => pyUpdate(fieldName, layerState, v!),
          ),
        ],
      );
    },
    "validation_test_split": (layerState, v) {
      String fieldName = "validation_test_split";
      double dv = double.tryParse(v)!;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Validation Test Split"),
          Slider(
            value: dv,
            divisions: 10,
            label: "$dv",
            onChanged: (v) => pyUpdate(fieldName, layerState, v.toString()),
          ),
        ],
      );
    },
  };

  @override
  void initState() {
    super.initState();
    Provider.of<DialogueInterface>(context, listen: false).addListener(() {
      _controllers.clear();
      _widgetErrors.clear();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _widgetErrors.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget dialogue = const Text(
      "Welcome to MAI!",
      style: TextStyle(fontSize: 24, color: Colors.white),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
              headline1: Theme.of(context).textTheme.headline1!.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                  ),
            ),
      ),
      child: Container(
        color: mainColors.shade900,
        height: MediaQuery.of(context).size.height,
        width: Main.getSidePanelWidth(context),
        child: Consumer<DialogueInterface>(
          builder: (context, interface, child) {
            if (interface.layerState != null) {
              dialogue = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${interface.layerState!.widget.type} Layer",
                      style: Theme.of(context).textTheme.headline1),
                  for (var setting in interface.settings.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _settingWidgets[setting.key]!(
                        interface.layerState!,
                        setting.value,
                      ),
                    )
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.all(10),
              child: dialogue,
            );
          },
        ),
      ),
    );
  }
}

class DialogueInterface extends ChangeNotifier {
  Map<String, String> settings = {};
  LayerTileState? layerState;

  void displaySettings(LayerTileState state) {
    settings = state.layerSettings!;
    layerState = state;
    notifyListeners();
  }
}
