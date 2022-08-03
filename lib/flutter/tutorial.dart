import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tutorial_data.dart';
import 'dialogue_panel.dart';

class Tutorial extends StatefulWidget {
  final bool selectionPanel;
  final bool selected;
  final TutorialData data;
  final _TutorialState? _tileState;

  const Tutorial(
    this.selectionPanel,
    this.data, {
    required this.selected,
    tileState,
    Key? key,
  })  : _tileState = tileState,
        super(key: key);

  @override
  State<Tutorial> createState() => _TutorialState();
}

class _TutorialState extends State<Tutorial> {
  int totalPages = 0;
  int page = 0;
  bool completed = false;

  void setCompleted() => setState(() => completed = true);

  @override
  void initState() {
    super.initState();
    if (widget.selected) {
      var interface = Provider.of<DialogueInterface>(context, listen: false);
      interface.initTutorial(Tutorial(
        false,
        widget.data,
        selected: false,
        tileState: this,
      ));
      Future.delayed(Duration.zero, interface.loaded);
    }
    totalPages = widget.data.meat.length;
  }

  @override
  void didUpdateWidget(covariant Tutorial oldWidget) {
    super.didUpdateWidget(oldWidget);
    page = 0;
    totalPages = widget.data.meat.length;
  }

  Widget _tutorialItem(TutorialItem item) {
    switch (item.type) {
      case ItemType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            item.data.join(),
            style: Theme.of(context).textTheme.bodyText2,
          ),
        );
      case ItemType.image:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 35),
          child: Center(child: Image.asset("assets/${item.data[0]}")),
        );
      default:
        return Text(
          "Error - ${item.type.name}: " + item.data.join(),
          style: Theme.of(context).textTheme.bodyText2!.copyWith(
                color: Colors.red,
              ),
        );
    }
  }

  Widget _displayItem(ItemType type, String data, String colorHex) {
    var color = Color(int.parse(colorHex, radix: 16));
    Widget child;
    switch (type) {
      case ItemType.text:
        child = Center(
          child: Text(
            data,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.headline5!.copyWith(color: color),
          ),
        );
        break;
      case ItemType.image:
        child = Image.asset("assets/$data", color: color);
        break;
      case ItemType.icon:
        child = Icon(
          IconData(int.parse(data, radix: 16), fontFamily: "MaterialIcons"),
          color: color,
          size: 48,
        );
        break;
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionPanel) {
      return Center(
        child: ListTile(
          leading: _displayItem(
            widget.data.displayItemType,
            widget.data.displayData,
            widget.data.displayColor,
          ),
          title: Text(
            widget.data.title,
            style: Theme.of(context).textTheme.headline6,
          ),
          minVerticalPadding: 15,
          tileColor: completed ? Colors.green.shade900 : Colors.blue.shade900,
          hoverColor: completed ? Colors.green.shade800 : Colors.blue.shade800,
          selectedTileColor:
              completed ? Colors.green.shade700 : Colors.blue.shade700,
          selected: widget.selected,
          onTap: () => Provider.of<DialogueInterface>(context, listen: false)
              .tutorial = Tutorial(
            false,
            widget.data,
            selected: false,
            tileState: this,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.data.title,
                  style: Theme.of(context).textTheme.headline1,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ScrollController(),
                shrinkWrap: true,
                itemCount: widget.data.meat[page].length,
                itemBuilder: (context, i) =>
                    _tutorialItem(widget.data.meat[page][i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                    onPressed:
                        page == 0 ? null : () => setState(() => page -= 1),
                    child: const Text("Back")),
                Text("${page + 1}/$totalPages"),
                TextButton(
                    onPressed: page == totalPages - 1
                        ? null
                        : () => setState(() {
                              page += 1;
                              if (page == totalPages - 1) {
                                completed = true;
                                widget._tileState!.setCompleted();
                              }
                            }),
                    child: const Text("Continue")),
              ],
            )
          ],
        ),
      );
    }
  }
}
