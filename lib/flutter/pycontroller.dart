import 'dart:io';
import 'dart:convert';

class PyController {
  Process? _python;

  PyController() {
    _init();
  }

  void _init() async {
    _python = await Process.start(
      "python",
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

  void pyInputHandler(String data) {}

  void dispose() {
    _python?.stdin.writeln("Exit");
    _python?.kill();
  }
}
