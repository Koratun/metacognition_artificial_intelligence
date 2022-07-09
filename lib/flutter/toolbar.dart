import 'package:flutter/material.dart';

import 'schemas/command_type_enum.dart';
import 'schemas/compile_error_reason_enum.dart';
import 'schemas/compile_error_disjointed_response.dart';
import 'schemas/compile_error_response.dart';
import 'schemas/compile_error_settings_validation_response.dart';
import 'schemas/compile_success_response.dart';
import 'schemas/graph_exception_response.dart';

import 'pycontroller.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            // Replace when Dialogue panel is complete
            onTap: () => setState(() => fitted = true),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.settings,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
        ),
        Material(
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
                        debugPrint(
                            "WARNING!! Unhandled response: $response from Compile button");
                      }
                    });
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.api,
                color: Colors.yellow.shade400,
                size: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
