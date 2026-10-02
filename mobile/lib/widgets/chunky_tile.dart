import 'package:flutter/material.dart';
import 'package:zaban/theme/app_theme.dart';

/// Tappable 3D card used for answer options and word chips.
///
/// Draws a 2px border with a thicker bottom edge that flattens on press.
class ChunkyTile extends StatefulWidget {
  const ChunkyTile({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.face,
    this.edge,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.radius = 14,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  /// Override colors (e.g. green for a matched pair). Defaults follow [selected].
  final Color? face;
  final Color? edge;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  State<ChunkyTile> createState() => _ChunkyTileState();
}

class _ChunkyTileState extends State<ChunkyTile> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final face =
        widget.face ?? (widget.selected ? AppColors.skySoft : AppColors.snow);
    final edge =
        widget.edge ?? (widget.selected ? AppColors.skyBorder : AppColors.line);
    final r = BorderRadius.circular(widget.radius);
    const depth = 3.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: EdgeInsets.only(
          top: _pressed ? depth : 0,
          bottom: _pressed ? 0 : depth,
        ),
        decoration: BoxDecoration(
          color: _pressed ? Colors.transparent : edge,
          borderRadius: r,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: face,
            borderRadius: r,
            border: Border.all(color: edge, width: 2),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.selected ? AppColors.skyDark : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
