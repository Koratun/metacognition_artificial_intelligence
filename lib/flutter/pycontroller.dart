import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';

import 'schemas/schema.dart';
import 'schemas/event_type_enum.dart';
import 'schemas/response_type_enum.dart';
import 'schemas/command_type_enum.dart';

import 'console.dart';

//Used for debugging
const bool _echo = true;

class PyController {
  static Process? _python;
  static Process? _ai;
  static Map<String, void Function(RequestResponseSchema)> responseActions = {};
  static Map<EventType, List<void Function(Schema)>> eventHandlers = {};
  static Map<EventType, List<Schema>> eventQueue = {};

  static Future<void> init() async {
    _python = await Process.start(
      ".venv\\Scripts\\python.exe",
      ["lib\\python\\dart_endpoint.py"],
      runInShell: true,
    );
    _python?.stdout.transform(utf8.decoder).forEach((data) {
      for (var msg in data.trimRight().split('\n')) {
        _pyInputHandler(msg);
      }
    });
    _python?.stderr.transform(utf8.decoder).forEach(debugPrint);
  }

  static Future<void> reset() async {
    _python?.stdin.writeln("Exit");
    _python?.kill();
    await init();
  }

  static Future<void> trainAI(BuildContext context) async {
    var console = Provider.of<ConsoleInterface>(context, listen: false);
    console.log("Loading model...", Logging.info);
    _ai = await Process.start(
      ".venv\\Scripts\\python.exe",
      ["data\\MAI.py"],
      runInShell: true,
    );
    _ai?.exitCode.then((exitCode) {
      if (exitCode != 0) {
        console.log(
          "An error occurred while training this model. Error code $exitCode",
          Logging.error,
        );
      } else {
        console.log("Training complete!", Logging.info);
      }
    });
    console.log("Beginning training...", Logging.info);
    _ai?.stdout.transform(utf8.decoder).forEach((data) {
      for (var s in data.trim().split('\n')) {
        if (s.contains(RegExp(r"\S"))) {
          if (s.contains("Epoch")) {
            s = "\n" + s;
          }
          console.log(s, Logging.info);
        }
      }
    });
    _ai?.stderr
        .transform(utf8.decoder)
        .forEach((s) => console.log(s, Logging.warn));
  }

  static void request(
    CommandType c,
    void Function(RequestResponseSchema) responseAction, {
    RequestResponseSchema? data,
  }) {
    data ??= RequestResponseSchema();
    PyController.responseActions[data.requestId] = responseAction;
    _python?.stdin.writeln(c.name + json.encode(data.toJson()));
    if (_echo) {
      debugPrint("Request sent: ${c.name + json.encode(data.toJson())}");
    }
  }

  static void registerEventHandler(
    EventType eventType,
    void Function(Schema) handler,
  ) {
    if (eventHandlers.containsKey(eventType)) {
      eventHandlers[eventType]!.add(handler);
    } else {
      eventHandlers[eventType] = [handler];
    }
    if (eventQueue.containsKey(eventType)) {
      for (var event in eventQueue[eventType]!) {
        handler(event);
      }
      eventQueue.remove(eventType);
    }
  }

  static void _pyInputHandler(String data) {
    // Separate the text preceding the first [ or {
    // and the rest of the text.
    final Map<String, dynamic> responseData =
        json.decode(data.substring(data.indexOf(RegExp(r'[[{]'))));
    // Will throw a StateError if the incoming data is
    // an event rather than a response
    try {
      final ResponseType responseType = ResponseType.values.firstWhere(
          (e) => e.name == data.substring(0, data.indexOf(RegExp(r'[[{]'))));
      final RequestResponseSchema response =
          responseType.schemaFromJson!(responseData);

      responseActions[response.requestId]!(response);
      responseActions.remove(response.requestId);
      if (_echo) {
        debugPrint("Response: $responseData");
      }
    } on StateError {
      // If response is not a response type, then it is an event type
      final EventType eventType = EventType.values.firstWhere(
          (e) => e.name == data.substring(0, data.indexOf(RegExp(r'[[{]'))));
      final Schema event = eventType.schemaFromJson!(responseData);

      if (eventHandlers.containsKey(eventType)) {
        for (var handler in eventHandlers[eventType]!) {
          handler(event);
        }
      } else {
        if (eventQueue.containsKey(eventType)) {
          eventQueue[eventType]!.add(event);
        } else {
          eventQueue[eventType] = [event];
        }
      }
      if (_echo) {
        debugPrint("Event: ${eventType.name} -> $responseData");
      }
    }
  }

  static void dispose() {
    _python?.stdin.writeln("Exit");
    _python?.kill();
  }
}
