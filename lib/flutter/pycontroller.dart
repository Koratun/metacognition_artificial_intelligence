import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class PyController extends InheritedWidget {
  late final Process _python;
  bool initialized = false;

  // ignore: prefer_const_constructors_in_immutables
  PyController({Key? key, required Widget child})
      : super(key: key, child: child);

  void init() async {
    _python = await Process.start(
      "python",
      [".\\lib\\python\\main.py"],
      runInShell: true,
    );
    _python.stdout.transform(utf8.decoder).forEach(print);
    _python.stderr.transform(utf8.decoder).forEach(print);
    _python.stdin.writeln("Init");
    initialized = true;
  }

  static PyController of(BuildContext context) {
    final PyController? result =
        context.dependOnInheritedWidgetOfExactType<PyController>();
    assert(result != null, "No PyController found");
    return result!;
  }

  void dispose() {
    _python.stdin.writeln("Exit");
    _python.kill();
  }

  @override
  bool updateShouldNotify(PyController oldWidget) => false;
}
