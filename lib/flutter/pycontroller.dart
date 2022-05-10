import 'dart:io';
import 'dart:convert';
import 'response_schemas/response_type_enum.dart';
import 'response_schemas/startup_response.dart';
import 'response_schemas/compile_error_response.dart';
import 'response_schemas/compile_error_disjointed_response.dart';
import 'response_schemas/compile_error_settings_validation_response.dart';
import 'response_schemas/compile_success_response.dart';
import 'response_schemas/creation_response.dart';
import 'response_schemas/graph_exception_response.dart';
import 'response_schemas/success_fail_response.dart';
import 'response_schemas/validation_error_response.dart';

class PyController {
  Process? _python;

  PyController() {
    _init();
  }

  void _init() async {
    _python = await Process.start(
      ".venv\\Scripts\\python.exe",
      [".\\lib\\python\\dart_endpoint.py"],
      runInShell: true,
    );
    _python?.stdout.transform(utf8.decoder).forEach(print);
    _python?.stderr.transform(utf8.decoder).forEach(print);
  }

  static final PyController _theController = PyController();

  static PyController get get => _theController;

  void bindInputCallback(void Function(String) callback) =>
      _python?.stdout.transform(utf8.decoder).forEach(callback);

  void bindErrorCallback(void Function(String) callback) =>
      _python?.stderr.transform(utf8.decoder).forEach(callback);

  void sendMessage(String message) => _python?.stdin.writeln(message);

  void pyInputHandler(String data) {
    // Separate the text preceding the first [ or {
    // and the rest of the text.
    final ResponseType responseType = ResponseType.values.firstWhere((e) =>
        e.toString() ==
        "ResponseType." + data.substring(0, data.indexOf(RegExp(r'[[{]'))));
    final Map<String, dynamic> responseData =
        json.decode(data.substring(data.indexOf(RegExp(r'[[{]'))));
    switch (responseType) {
      case ResponseType.startup:
        {
          final StartupResponse response =
              StartupResponse.fromJson(responseData);
        }
        break;
      case ResponseType.successFail:
        {
          final SuccessFailResponse response =
              SuccessFailResponse.fromJson(responseData);
        }
        break;
      case ResponseType.creation:
        {
          final CreationResponse response =
              CreationResponse.fromJson(responseData);
        }
        break;
      case ResponseType.graphException:
        {
          final GraphExceptionResponse response =
              GraphExceptionResponse.fromJson(responseData);
        }
        break;
      case ResponseType.validationError:
        {
          final ValidationErrorResponse response =
              ValidationErrorResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileError:
        {
          final CompileErrorResponse response =
              CompileErrorResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileErrorSettingsValidation:
        {
          final CompileErrorSettingsValidationResponse response =
              CompileErrorSettingsValidationResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileErrorDisjointed:
        {
          final CompileErrorDisjointedResponse response =
              CompileErrorDisjointedResponse.fromJson(responseData);
        }
        break;
      case ResponseType.compileSuccess:
        {
          final CompileSuccessResponse response =
              CompileSuccessResponse.fromJson(responseData);
        }
        break;
      default:
        {
          print("Unknown response type: $responseType FIX IT!!!");
        }
        break;
    }
  }

  void dispose() {
    _python?.stdin.writeln("Exit");
    _python?.kill();
  }
}
