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

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          Overlay.of(context)!.insert(overlayEntry);
          debugPrint(Overlay.of(context)!.toString());
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
        child: CustomMultiChildLayout(
          delegate: _ButtonDropdownDelegate(size),
          children: [
            LayoutId(
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
            LayoutId(
              id: #wholeRegion,
              child: MouseRegion(
                onExit: (_) => setState(() {
                  overlayEntry.remove();
                }),
              ),
            ),
            LayoutId(
              id: #negativeRegion,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  overlayEntry.remove();
                }),
                child: SizedBox(
                  width: (widget.dropdownWidth ?? 200) - size.width,
                  height: size.height,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ButtonDropdownDelegate extends MultiChildLayoutDelegate {
  final Size buttonSize;

  _ButtonDropdownDelegate(this.buttonSize) : super();

  @override
  void performLayout(Size size) {
    final listSize = layoutChild(#list, BoxConstraints.loose(size));
    positionChild(#list, Offset(0, buttonSize.height));
    layoutChild(#negativeRegion, BoxConstraints.loose(size));
    positionChild(
        #negativeRegion, Offset(listSize.width - buttonSize.width, 0));
    layoutChild(
        #wholeRegion,
        BoxConstraints.tight(
            Size(listSize.width, listSize.height + buttonSize.height)));
    positionChild(#wholeRegion, Offset.zero);
  }

  @override
  bool shouldRelayout(_ButtonDropdownDelegate oldDelegate) => false;
}
