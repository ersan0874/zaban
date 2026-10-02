import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/theme/app_theme.dart';

/// Shared building blocks for the playful design system (ADR-015).

/// White card with the 2px line border used across the app.
class ZCard extends StatelessWidget {
  const ZCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.snow,
        borderRadius: r,
        border: Border.all(color: borderColor ?? AppColors.line, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Solid colored hero card with a darker bottom edge.
class ZBanner extends StatelessWidget {
  const ZBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color = AppColors.leaf,
    this.edge = AppColors.leafDark,
    this.trailing,
    this.child,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final Color edge;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(color: edge, borderRadius: r),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, borderRadius: r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 44),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 14),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section heading used above lists.
class ZSectionTitle extends StatelessWidget {
  const ZSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.vazirmatn(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Bordered stat box: colored icon, big number, small label.
class ZStatTile extends StatelessWidget {
  const ZStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.latin(fontSize: 18, color: AppColors.ink),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round avatar with the person's initial on a palette color.
class ZAvatar extends StatelessWidget {
  const ZAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  static const _colors = [
    AppColors.sky,
    AppColors.grape,
    AppColors.flame,
    AppColors.leaf,
    AppColors.coral,
    AppColors.sunDark,
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;
    final color = _colors[trimmed.hashCode.abs() % _colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.vazirmatn(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Thin rounded progress bar.
class ZProgressBar extends StatelessWidget {
  const ZProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.sun,
    this.height = 14,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

/// Friendly empty / error placeholder with an optional action.
class ZMessage extends StatelessWidget {
  const ZMessage({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color ?? AppColors.locked),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
                height: 1.6,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
