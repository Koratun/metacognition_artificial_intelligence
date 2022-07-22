import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'schemas/command_type_enum.dart';
import 'schemas/event_type_enum.dart';
import 'schemas/init_fit_event.dart';
import 'schemas/compile_error_disjointed_response.dart';
import 'schemas/compile_error_response.dart';
import 'schemas/compile_error_settings_validation_response.dart';
import 'schemas/compile_success_response.dart';
import 'schemas/graph_exception_response.dart';

import 'console.dart';
import 'dialogue_panel.dart';
import 'pycontroller.dart';
import 'main.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({Key? key}) : super(key: key);

  @override
  State<Toolbar> createState() => ToolbarState();
}

class ToolbarState extends State<Toolbar> {
  bool fitted = false;
  late final Map<String, String> fitSettings;
  late final String fitNodeId;
  bool? _compileSuccess;

  @override
  void initState() {
    super.initState();
    Provider.of<DialogueInterface>(context, listen: false)
        .initFitSettings(this);
    PyController.registerEventHandler(EventType.initFit, (event) {
      if (event is InitFitEvent) {
        fitNodeId = event.nodeId;
        fitSettings = event.settings;
      } else {
        Provider.of<ConsoleInterface>(context, listen: false).log(
          "Unhandled event in toolbar! $event",
          Logging.devError,
        );
      }
    });
  }

  void fitSuccess() => setState(() => fitted = true);

  void fitFailed() => setState(() => fitted = false);

  // The errors need better work to display their contents
  void _compileRequest() =>
      PyController.request(CommandType.compile, (response) {
        var console = Provider.of<ConsoleInterface>(context, listen: false);
        if (response is CompileSuccessResponse) {
          console.log("Compilation succesful!", Logging.info);
          setState(() => _compileSuccess = true);
        } else if (response is CompileErrorSettingsValidationResponse) {
          console.log(response.errors.toString(), Logging.error);
          setState(() => _compileSuccess = false);
        } else if (response is CompileErrorDisjointedResponse) {
          console.log(response.reason.name, Logging.error);
          setState(() => _compileSuccess = false);
        } else if (response is CompileErrorResponse) {
          console.log(response.reason.name, Logging.error);
          setState(() => _compileSuccess = false);
        } else if (response is GraphExceptionResponse) {
          console.log(response.error, Logging.error);
          setState(() => _compileSuccess = false);
        } else {
          console.log(
            "WARNING!! Unhandled response: $response from Compile button",
            Logging.devError,
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColors.shade900,
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: mainColors.shade800,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              // Replace when Dialogue panel is complete
              onTap: () {
                Provider.of<DialogueInterface>(context, listen: false)
                    .displayFitSettings();
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.settings,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
          ),
          Material(
            color: fitted ? mainColors.shade800 : mainColors.shade900,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: fitted ? _compileRequest : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.api,
                  color: fitted
                      ? (_compileSuccess == null
                          ? Colors.yellow.shade400
                          : (_compileSuccess! ? Colors.green : Colors.red))
                      : const Color.fromARGB(140, 255, 238, 88),
                  size: 48,
                ),
              ),
            ),
          ),
          Material(
            color: _compileSuccess != null && _compileSuccess!
                ? mainColors.shade800
                : mainColors.shade900,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: _compileSuccess != null && _compileSuccess!
                  // Replace when training logic is ready
                  ? () => debugPrint("Train")
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.school,
                  color: _compileSuccess != null && _compileSuccess!
                      ? mainColors.shade400
                      : const Color.fromARGB(140, 62, 185, 199),
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
