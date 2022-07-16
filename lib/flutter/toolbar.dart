import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'schemas/command_type_enum.dart';
import 'schemas/compile_error_disjointed_response.dart';
import 'schemas/compile_error_response.dart';
import 'schemas/compile_error_settings_validation_response.dart';
import 'schemas/compile_success_response.dart';
import 'schemas/graph_exception_response.dart';

import 'console.dart';
import 'pycontroller.dart';
import 'main.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({Key? key}) : super(key: key);

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  bool fitted = false;
  bool? compileSuccess;

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
              onTap: () => setState(() => fitted = true),
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
              onTap: fitted
                  ? () {
                      PyController.request(CommandType.compile, (response) {
                        if (response is CompileSuccessResponse) {
                          setState(() => compileSuccess = true);
                        } else if (response
                            is CompileErrorSettingsValidationResponse) {
                          setState(() => compileSuccess = false);
                        } else if (response is CompileErrorDisjointedResponse) {
                          setState(() => compileSuccess = false);
                        } else if (response is CompileErrorResponse) {
                          setState(() => compileSuccess = false);
                        } else if (response is GraphExceptionResponse) {
                          setState(() => compileSuccess = false);
                        } else {
                          Provider.of<ConsoleInterface>(context, listen: false)
                              .log(
                            "WARNING!! Unhandled response: $response from Compile button",
                            Logging.devError,
                          );
                        }
                      });
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.api,
                  color: fitted
                      ? (compileSuccess == null
                          ? Colors.yellow.shade400
                          : (compileSuccess! ? Colors.green : Colors.red))
                      : const Color.fromARGB(140, 255, 238, 88),
                  size: 48,
                ),
              ),
            ),
          ),
          Material(
            color: compileSuccess != null && compileSuccess!
                ? mainColors.shade800
                : mainColors.shade900,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: compileSuccess != null && compileSuccess!
                  // Replace when training logic is ready
                  ? () => debugPrint("Train")
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.school,
                  color: compileSuccess != null && compileSuccess!
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
