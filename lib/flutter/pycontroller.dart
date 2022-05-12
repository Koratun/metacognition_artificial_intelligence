import 'dart:io';
import 'dart:convert';

import 'schemas/response_type_enum.dart';
import 'schemas/startup_response.dart';
import 'schemas/compile_error_response.dart';
import 'schemas/compile_error_disjointed_response.dart';
import 'schemas/compile_error_settings_validation_response.dart';
import 'schemas/compile_success_response.dart';
import 'schemas/creation_response.dart';
import 'schemas/graph_exception_response.dart';
import 'schemas/success_fail_response.dart';
import 'schemas/validation_error_response.dart';
import 'schemas/schema.dart';
import 'schemas/command_enum.dart';

class PyController {
  Process? _python;
  void Function(Schema)? responseAction;

  PyController() {
    _init();
  }

  void _init() async {
    _python = await Process.start(
      ".venv\\Scripts\\python.exe",
      [".\\lib\\python\\dart_endpoint.py"],
      runInShell: true,
    );
    _python?.stdout.transform(utf8.decoder).forEach(pyInputHandler);
    _python?.stderr.transform(utf8.decoder).forEach(print);
  }

  static final PyController _theController = PyController();

  static PyController get get => _theController;

  void bindInputCallback(void Function(String) callback) =>
      _python?.stdout.transform(utf8.decoder).forEach(callback);

  void bindErrorCallback(void Function(String) callback) =>
      _python?.stderr.transform(utf8.decoder).forEach(callback);

  void request(Command c, void Function(Schema) responseAction,
      {Schema data = const Schema()}) {
    this.responseAction = responseAction;
    _python?.stdin.writeln(c.name + json.encode(data.toJson()));
  }

  void pyInputHandler(String data) {
    // Separate the text preceding the first [ or {
    // and the rest of the text.
    final ResponseType responseType = ResponseType.values.firstWhere(
        (e) => e.name == data.substring(0, data.indexOf(RegExp(r'[[{]'))));
    final Map<String, dynamic> responseData =
        json.decode(data.substring(data.indexOf(RegExp(r'[[{]'))));
    dynamic response;
    switch (responseType) {
      case ResponseType.startup:
        {
          response = StartupResponse.fromJson(responseData);
        }
        break;
      case ResponseType.successFail:
        {
          response = SuccessFailResponse.fromJson(responseData);
        }
        break;
      case ResponseType.creation:
        {
          response = CreationResponse.fromJson(responseData);
        }
        break;
      case ResponseType.graphException:
        {
          response = GraphExceptionResponse.fromJson(responseData);
        }
        break;
      case ResponseType.validationError:
        {
          response = ValidationErrorResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileError:
        {
          response = CompileErrorResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileErrorSettingsValidation:
        {
          response =
              CompileErrorSettingsValidationResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileErrorDisjointed:
        {
          response = CompileErrorDisjointedResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileSuccess:
        {
          response = CompileSuccessResponse.fromJson(responseData);
        }
        break;
      default:
        {
          print("Unknown response type: $responseType FIX IT!!!");
        }
        break;
    }
    if (response != null) {
      responseAction!(response);
    }
    responseAction = null;
  }

  void dispose() {
    _python?.stdin.writeln("Exit");
    _python?.kill();
  }
}
