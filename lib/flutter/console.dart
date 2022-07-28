import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Console extends StatefulWidget {
  const Console({Key? key}) : super(key: key);

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 200,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: const Color.fromARGB(255, 0, 17, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Console",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Expanded(
              child: Consumer<ConsoleInterface>(
                builder: (context, interface, child) {
                  return ListView.builder(
                    reverse: true,
                    addAutomaticKeepAlives: false,
                    cacheExtent: 100,
                    itemCount: interface._logs.length,
                    itemBuilder: (context, i) => interface._logs[i],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

enum Logging {
  info,
  warn,
  error,
  devError,
}

class ConsoleInterface extends ChangeNotifier {
  final List<Widget> _logs = [];
  bool _liveLog = false;

  static const _logColors = {
    Logging.info: Colors.white,
    Logging.warn: Colors.yellow,
    Logging.error: Colors.red,
    // Colors.redAccent[400] as a const
    Logging.devError: Color.fromARGB(255, 255, 23, 68),
  };

  void log(String msg, Logging state) {
    if (state == Logging.devError) {
      msg = "Dev error -> $msg - This is a developer's fault!";
    }
    if (msg.contains(RegExp(r"\[[=>.]+\]"))) {
      if (!_liveLog) {
        _liveLog = true;
        _logs.insert(0, Text(msg, style: TextStyle(color: _logColors[state]!)));
      } else {
        _logs[0] = Text(msg, style: TextStyle(color: _logColors[state]!));
      }
    } else {
      _liveLog = false;
      _logs.insert(0, Text(msg, style: TextStyle(color: _logColors[state])));
    }
    notifyListeners();
  }
}
