import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';

class WindowStyleDropdownMenu extends StatefulWidget {
  final String buttonTitle;
  final TextStyle? buttonTitleStyle;
  final double? dropdownWidth;
  final Color? dropdownBackgroundColor;
  final List<ListTile> dropdownItems;

  const WindowStyleDropdownMenu(
      {Key? key,
      required this.buttonTitle,
      required this.dropdownItems,
      this.buttonTitleStyle,
      this.dropdownWidth,
      this.dropdownBackgroundColor})
      : super(key: key);

  @override
  State<WindowStyleDropdownMenu> createState() =>
      _WindowStyleDropdownMenuState();
}

class _WindowStyleDropdownMenuState extends State<WindowStyleDropdownMenu> {
  late final OverlayEntry overlayEntry = createOverlayEntry();
  bool removed = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          Overlay.of(context)!.insert(overlayEntry);
        });
      },
      child: Text(
        widget.buttonTitle,
        style: widget.buttonTitleStyle ??
            TextStyle(color: Theme.of(context).primaryColorLight),
      ),
    );
  }

  OverlayEntry createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        width: widget.dropdownWidth ?? 200,
        child: CustomBoxy(
          delegate: _ButtonDropdownDelegate(size),
          children: [
            BoxyId(
              id: #list,
              child: Material(
                color: widget.dropdownBackgroundColor ??
                    Theme.of(context).primaryColorDark,
                elevation: 4.0,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: widget.dropdownItems,
                ),
              ),
            ),
            BoxyId(
              id: #wholeRegion,
              child: MouseRegion(
                onExit: (_) => setState(() {
                  overlayEntry.remove();
                  removed = true;
                }),
                opaque: false,
              ),
            ),
            BoxyId(
              id: #negativeRegion,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  if (!removed) {
                    overlayEntry.remove();
                  } else {
                    removed = false;
                  }
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ButtonDropdownDelegate extends BoxyDelegate {
  final Size buttonSize;

  _ButtonDropdownDelegate(this.buttonSize) : super();

  @override
  Size layout() {
    final list = getChild(#list);
    final wholeRegion = getChild(#wholeRegion);
    final negativeRegion = getChild(#negativeRegion);

    final listSize = list.layout(constraints);
    list.position(Offset(0, buttonSize.height));

    negativeRegion.layout(BoxConstraints.tight(
        Size(listSize.width - buttonSize.width, buttonSize.height)));
    negativeRegion.position(Offset(buttonSize.width, 0));

    final wholeSize = wholeRegion.layout(BoxConstraints.tight(
        Size(listSize.width, listSize.height + buttonSize.height)));
    wholeRegion.position(Offset.zero);
    return wholeSize;
  }

  @override
  bool shouldRelayout(_ButtonDropdownDelegate oldDelegate) => false;
}
