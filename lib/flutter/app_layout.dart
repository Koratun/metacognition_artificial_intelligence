import 'package:flutter/material.dart';

import 'selection_panel.dart';

// A custom multi-child layout widget that sizes and positions each child
enum _Panels {
  creation,
  selection,
  dialogue,
  report,
  creationTools,
}

class AppLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    Size selectionSize = Size.zero;
    Size dialogueSize = Size.zero;

    if (hasChild(_Panels.selection)) {
      selectionSize =
          layoutChild(_Panels.selection, BoxConstraints.loose(size));
    }

    if (hasChild(_Panels.dialogue)) {
      dialogueSize = layoutChild(_Panels.dialogue, BoxConstraints.loose(size));
      positionChild(
          _Panels.dialogue, Offset(size.width - dialogueSize.width, 0));
    }

    if (hasChild(_Panels.report)) {
      Size maxReportSize = Size(
          size.width - dialogueSize.width - selectionSize.width, size.height);
      Size reportSize =
          layoutChild(_Panels.report, BoxConstraints.loose(maxReportSize));
      positionChild(
          _Panels.report,
          Offset(size.width / 2 - reportSize.width / 2,
              size.height - reportSize.height));
    }

    if (hasChild(_Panels.creationTools)) {
      Size creationToolsSize =
          layoutChild(_Panels.creationTools, BoxConstraints.loose(size));
      positionChild(_Panels.creationTools,
          Offset(size.width / 2 - creationToolsSize.width / 2, 0));
    }

    if (hasChild(_Panels.creation)) {
      layoutChild(_Panels.creation, BoxConstraints.tight(size));
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => false;
}

class AppLayout extends StatefulWidget {
  const AppLayout({Key? key}) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(delegate: AppLayoutDelegate(), children: [
      LayoutId(
        id: _Panels.creation,
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
      LayoutId(id: _Panels.selection, child: SelectionPanel()),
      LayoutId(
          id: _Panels.dialogue,
          child: SizedBox(
            width: 200,
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
          )),
      LayoutId(
          id: _Panels.report,
          child: SizedBox(
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
          )),
      LayoutId(
          id: _Panels.creationTools,
          child: SizedBox(
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
          )),
    ]);
  }
}
