import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dialogue_panel.dart';
import 'selection_panel.dart';
import 'console.dart';
import 'creation_canvas.dart';
import 'toolbar.dart';
import 'pycontroller.dart';

void main() {
  runApp(const Main());
}

extension StringUtils on String {
  bool get isUpper {
    return !contains(RegExp(r'[a-z]'));
  }

  String get snakeCase {
    String snaked = "";
    for (var c in characters) {
      if (c.isUpper) {
        snaked += "_" + c.toLowerCase();
      } else {
        snaked += c;
      }
    }
    return snaked;
  }

  String get camelCase {
    String camel = "";
    bool toCap = false;
    for (var c in characters) {
      if (c == "_") {
        toCap = true;
      } else if (toCap) {
        camel += c.toUpperCase();
        toCap = false;
      } else {
        camel += c;
      }
    }
    return camel;
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  static double getSidePanelWidth(BuildContext context) {
    double totalWidth = MediaQuery.of(context).size.width;
    if (totalWidth <= 1264) {
      return 90 * 3;
    } else if (totalWidth >= 1920) {
      return 128 * 3;
    } else {
      return (totalWidth - 1264) / (1920 - 1264) * (128 * 3 - 90 * 3) + 90 * 3;
    }
  }

  @override
  State<Main> createState() => _MainState();
}

const MaterialColor mainColors = MaterialColor(0xFF007EA7, <int, Color>{
  50: Color(0xFFCCDBDC),
  100: Color.fromARGB(255, 153, 207, 211),
  200: Color(0xFF9AD1D4),
  300: Color.fromARGB(255, 122, 211, 221),
  400: Color.fromARGB(255, 62, 185, 199),
  500: Color(0xFF007EA7),
  600: Color.fromARGB(255, 0, 102, 136),
  700: Color.fromARGB(255, 0, 77, 102),
  800: Color(0xFF003249),
  900: Color.fromARGB(255, 0, 27, 39),
});

class _MainState extends State<Main> with TickerProviderStateMixin {
  // This widget is the root of the application.
  @override
  void initState() {
    super.initState();
    PyController.init();
  }

  @override
  void dispose() {
    PyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metacognition Artificial Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: mainColors,
        backgroundColor: mainColors[900],
        canvasColor: Colors.black,
        textTheme: Typography.whiteRedmond,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (context) => CreationCanvasInterface(this)),
              ChangeNotifierProvider(create: (context) => DialogueInterface()),
              ChangeNotifierProvider(create: (context) => ConsoleInterface()),
            ],
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CreationCanvas(),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SelectionPanel(),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [Toolbar(), Console()],
                        ),
                      ),
                      const DialoguePanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
