import 'package:flutter/material.dart';

import 'mouse_hugger.dart';
import 'selection_panel.dart';
import 'floating_widget_layout.dart';

void main() {
  runApp(const Main());
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

class _MainState extends State<Main> {
  Widget? _hugger;
  Offset mousePos = Offset.zero;

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metacognition Artificial Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        canvasColor: Colors.black,
        textTheme: Typography.blackRedmond,
      ),
      home: Scaffold(
        body: MouseHugger(
          huggerChange: (hugger, event) => setState(() {
            mousePos = event.position;
            _hugger = hugger;
          }),
          child: Builder(
            builder: (context) => Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        'Creation',
                        style: Theme.of(context).textTheme.headline4!.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SelectionPanel(),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 40,
                              child: Container(
                                color: Colors.orange,
                                child: Center(
                                  child: Text(
                                    'Tools',
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 800,
                              height: 200,
                              child: Container(
                                color: Colors.green,
                                child: Center(
                                  child: Text(
                                    'Report',
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: Main.getSidePanelWidth(context),
                        height: 600,
                        child: Container(
                          color: Colors.yellow,
                          child: Center(
                            child: Text(
                              'Dialogue',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {},
                    onPointerUp: (_) => setState(() => _hugger = null),
                    onPointerCancel: (_) => setState(() => _hugger = null),
                    onPointerMove: _hugger == null
                        ? (_) {}
                        : (details) =>
                            setState(() => mousePos = details.position),
                    child: CustomSingleChildLayout(
                      delegate:
                          FloatingWidgetLayoutDelegate(position: mousePos),
                      child: _hugger ?? const Center(),
                    ),
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
