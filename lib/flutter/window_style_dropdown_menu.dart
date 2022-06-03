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
  OverlayEntry? overlayEntry;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          overlayEntry = createOverlayEntry();
          Overlay.of(context)?.insert(overlayEntry!);
        });
        debugDumpApp();
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
      maintainState: true,
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        width: widget.dropdownWidth ?? 200,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height,
              width: widget.dropdownWidth ?? 200,
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
            MouseRegion(
              onExit: (_) => setState(() => overlayEntry!.remove()),
              child: const SizedBox(),
            ),
            Positioned(
              right: widget.dropdownWidth ?? 200,
              top: 0,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  overlayEntry!.remove();
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
