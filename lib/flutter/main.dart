import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';

import 'mouse_hugger.dart';
import 'selection_panel.dart';
import 'floating_widget_layout.dart';
import 'layer_tile.dart';
import 'creation_canvas.dart';

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

class _MainState extends State<Main> with TickerProviderStateMixin {
  Widget? _hugger;
  Offset mousePos = Offset.zero;
  LayerTile? _huggerParent;
  final CreationCanvasNotifier _canvasNotifier = CreationCanvasNotifier();
  late final CreationCanvasDelegate _creationCanvasDelegate =
      CreationCanvasDelegate(this, _canvasNotifier);

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
          huggerChange: (hugger, event, layerTileState) => setState(() {
            mousePos = event.position;
            _hugger = hugger;
            _huggerParent = layerTileState;
          }),
          child: Builder(
            builder: (context) => Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    child: CustomMultiChildLayout(
                      delegate: _creationCanvasDelegate,
                      children: [
                        for (var i = 0;
                            i < _creationCanvasDelegate.childCount();
                            i++)
                          LayoutId(
                            id: i,
                            child: _creationCanvasDelegate
                                .childList()
                                .elementAt(i),
                          )
                      ],
                    ),
                    color: Colors.black,
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
                    onPointerUp: (event) {
                      SchedulerBinding.instance?.addPostFrameCallback((_) {
                        BoxHitTestResult result = BoxHitTestResult();
                        final renderBox = context.findRenderObject();
                        if (renderBox is RenderBox) {
                          renderBox.hitTest(result, position: event.position);
                          for (final hitEntry in result.path) {
                            if (hitEntry.target is RenderBox) {
                              var target = hitEntry.target as RenderBox;
                              // hitEntry.target.handleEvent(event, hitEntry);
                            }
                          }
                        }
                      });
                      setState(() {
                        _hugger = null;
                      });
                    },
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

// Might need this later to make a manual hit test against the back canvas
// when we drop a tile into it

// SchedulerBinding.instance?.addPostFrameCallback((_) {
//   if (_lastClick == null) {
//     print("Event was null");
//     return;
//   }
//   BoxHitTestResult result = BoxHitTestResult();
//   final renderBox = context.findRenderObject();
//   if (renderBox is RenderBox) {
//     renderBox.hitTest(result, position: huggerLocation);
//     for (final hitEntry in result.path) {
//       if (hitEntry.target is RenderPointerListener) {
//         hitEntry.target.handleEvent(_lastClick!, hitEntry);
//       }
//     }
//   }
// });