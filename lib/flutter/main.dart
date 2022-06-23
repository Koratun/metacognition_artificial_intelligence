import 'package:flutter/material.dart';
import 'selection_panel.dart';
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

const MaterialColor mainColors = MaterialColor(0xFF007EA7, <int, Color>{
  50: Color(0xFFCCDBDC),
  100: Color.fromARGB(255, 153, 207, 211),
  200: Color(0xFF9AD1D4),
  300: Color.fromARGB(255, 137, 204, 209),
  400: Color.fromARGB(255, 62, 185, 199),
  500: Color(0xFF007EA7),
  600: Color.fromARGB(255, 0, 102, 136),
  700: Color.fromARGB(255, 0, 77, 102),
  800: Color(0xFF003249),
  900: Color.fromARGB(255, 0, 27, 39),
});

class _MainState extends State<Main>
    with TickerProviderStateMixin, ChangeNotifier {
  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metacognition Artificial Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: mainColors,
        backgroundColor: mainColors[900],
        canvasColor: Colors.black,
        textTheme: Typography.blackRedmond,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Stack(
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
                        children: [
                          SizedBox(
                            width: 150,
                            height: 40,
                            child: Container(
                              color: Colors.orange,
                              child: Center(
                                child: Text(
                                  'Tools',
                                  style: Theme.of(context).textTheme.headline6,
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
                                  style: Theme.of(context).textTheme.headline6,
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
            ],
          ),
        ),
      ),
    );
  }
}
