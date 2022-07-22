import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'schemas/dtype_enum.dart';
import 'schemas/command_type_enum.dart';
import 'schemas/update_layer.dart';
import 'schemas/graph_exception_response.dart';
import 'schemas/validation_response.dart';

import 'layer_tile.dart';
import 'toolbar.dart';
import 'console.dart';
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

  void pyUpdate(
    String fieldName,
    DialogueInterface interface,
    String v,
  ) {
    interface._settings[fieldName] = v;
    PyController.request(
      CommandType.update,
      (response) {
        var console = Provider.of<ConsoleInterface>(context, listen: false);
        if (response is GraphExceptionResponse) {
          console.log(
            "$fieldName setting is incorrect" +
                (interface._layerState != null
                    ? " for this layer type: ${interface._layerState!.widget.type}"
                    : ""),
            Logging.devError,
          );
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
              if (errors.containsKey(field)) {
                console.log(
                  (interface._layerState != null
                          ? "${interface._layerState!.layerSettings!['name'] ?? interface._layerState!.widget.type}"
                          : "Fit") +
                      " -> $field: ${errors[field]!}",
                  Logging.error,
                );
              }
            }
            if (errors.isEmpty) {
              console.log("Settings accepted!", Logging.info);
              if (interface._layerState == null) {
                interface._toolbarState.fitSuccess();
              }
            } else {
              if (interface._layerState == null) {
                interface._toolbarState.fitFailed();
              }
            }
          });
        } else {
          console.log(
            "WARNING!! Unhandled response: $response from $fieldName setting widget",
            Logging.devError,
          );
        }
      },
      data: UpdateLayer(
          interface._layerState != null
              ? interface._layerState!.nodeId!
              : interface._toolbarState.fitNodeId,
          {fieldName: v}),
    );
  }

  Widget _plainTextSetting(
    String fieldName,
    String label,
    DialogueInterface interface,
    String v,
  ) {
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
      onChanged: (v) => pyUpdate(fieldName, interface, v),
    );
  }

  Widget _plainIntegerSetting(
    String fieldName,
    String label,
    DialogueInterface interface,
    String v,
  ) {
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
          label,
          style: Theme.of(context).textTheme.bodyText2!.copyWith(
                color: Colors.grey,
              ),
        ),
        border: const OutlineInputBorder(),
        errorText: _widgetErrors[fieldName],
      ),
      onChanged: (v) => pyUpdate(fieldName, interface, v),
    );
  }

  late final _settingWidgets = <
      String,
      Widget Function(
    DialogueInterface,
    String,
  )>{
    "name": (interface, v) =>
        _plainTextSetting("name", "Variable Name", interface, v),
    "shape": (interface, v) =>
        _plainTextSetting("shape", "Shape", interface, v),
    "oldRangeMin": (interface, v) =>
        _plainTextSetting("oldRangeMin", "Old range minimum", interface, v),
    "oldRangeMax": (interface, v) =>
        _plainTextSetting("oldRangeMax", "Old range maximum", interface, v),
    "newRangeMin": (interface, v) =>
        _plainTextSetting("newRangeMin", "New range minimum", interface, v),
    "newRangeMax": (interface, v) =>
        _plainTextSetting("newRangeMax", "New range maximum", interface, v),
    "units": (interface, v) =>
        _plainIntegerSetting("units", "Units", interface, v),
    "batchSize": (interface, v) =>
        _plainIntegerSetting("batchSize", "Batch Size", interface, v),
    "epochs": (interface, v) =>
        _plainIntegerSetting("epochs", "Epochs", interface, v),
    "nClasses": (interface, v) => _plainIntegerSetting(
        "nClasses", "Number of Classifications", interface, v),
    "dtype": (interface, v) {
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
            onChanged: (v) => pyUpdate(fieldName, interface, v!),
          ),
        ],
      );
    },
    "validationTestSplit": (interface, v) {
      String fieldName = "validationTestSplit";
      double dv = double.tryParse(v)!;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Validation Test Split"),
          Slider(
            value: dv,
            divisions: 10,
            label: "$dv",
            onChanged: (v) => pyUpdate(fieldName, interface, v.toString()),
          ),
        ],
      );
    },
    "shuffle": (interface, v) {
      String fieldName = "shuffle";
      bool on = v == "True";
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                "Shuffle",
                style: Theme.of(context).textTheme.bodyText2!.copyWith(
                      color: Colors.white,
                    ),
              )),
          Switch(
            value: on,
            onChanged: (v) =>
                pyUpdate(fieldName, interface, v ? "True" : "False"),
          )
        ],
      );
    }
  };

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
            if (interface._settings.isNotEmpty) {
              dialogue = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      interface._layerState != null
                          ? "${interface._layerState!.widget.type} Layer"
                          : "Fit Settings",
                      style: Theme.of(context).textTheme.headline1),
                  for (var setting in interface._settings.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _settingWidgets[setting.key]!(
                        interface,
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
  Map<String, String> _settings = {};
  LayerTileState? _layerState;
  late final ToolbarState _toolbarState;

  void displayLayerSettings(LayerTileState state) {
    _settings = state.layerSettings!;
    _layerState = state;
    notifyListeners();
  }

  void initFitSettings(ToolbarState state) {
    _toolbarState = state;
  }

  void displayFitSettings() {
    _settings = _toolbarState.fitSettings;
    _layerState = null;
    notifyListeners();
  }
}
