import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zaban/theme/app_theme.dart';

enum MascotMood { happy, cheer, sad, sleepy }

/// "Zabi", the app's round green owl. Drawn in code so it scales crisply
/// and needs no image assets. [bounce] adds a gentle idle hop.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 140,
    this.bounce = true,
  });

  final MascotMood mood;
  final double size;
  final bool bounce;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.bounce) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final hop = widget.mood == MascotMood.sleepy ? 0.0 : t;
        return Transform.translate(
          offset: Offset(0, -hop * widget.size * 0.06),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _MascotPainter(widget.mood, t),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.mood, this.t);

  final MascotMood mood;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    Paint fill(Color c) => Paint()..color = c;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, s * 0.95),
        width: s * (0.55 - t * 0.06),
        height: s * 0.07,
      ),
      fill(Colors.black.withValues(alpha: 0.08)),
    );

    // Wings (raised when cheering)
    final wingLift = mood == MascotMood.cheer ? 0.9 + t * 0.25 : 0.15;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(cx + side * s * 0.36, s * 0.6);
      canvas.rotate(side * -wingLift);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * s * 0.04, s * 0.06),
          width: s * 0.16,
          height: s * 0.3,
        ),
        fill(AppColors.leafDark),
      );
      canvas.restore();
    }

    // Body
    final body = Rect.fromCenter(
      center: Offset(cx, s * 0.56),
      width: s * 0.74,
      height: s * 0.76,
    );
    canvas.drawOval(body, fill(AppColors.leaf));
    // Ear tufts
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(cx + side * s * 0.12, s * 0.24)
        ..lineTo(cx + side * s * 0.3, s * 0.12)
        ..lineTo(cx + side * s * 0.3, s * 0.3)
        ..close();
      canvas.drawPath(path, fill(AppColors.leaf));
    }
    // Belly
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, s * 0.7),
        width: s * 0.44,
        height: s * 0.4,
      ),
      fill(const Color(0xFFD7F5BF)),
    );

    // Eyes
    final eyeY = s * 0.43;
    for (final side in [-1.0, 1.0]) {
      final c = Offset(cx + side * s * 0.15, eyeY);
      canvas.drawCircle(c, s * 0.13, fill(Colors.white));
      switch (mood) {
        case MascotMood.happy:
        case MascotMood.cheer:
          canvas.drawCircle(
            c + Offset(side * -s * 0.015, s * 0.01),
            s * 0.065,
            fill(const Color(0xFF2B3A45)),
          );
          canvas.drawCircle(
            c + Offset(side * -s * 0.035, -s * 0.02),
            s * 0.022,
            fill(Colors.white),
          );
        case MascotMood.sad:
          canvas.drawCircle(
            c + Offset(0, s * 0.04),
            s * 0.06,
            fill(const Color(0xFF2B3A45)),
          );
          // Droopy brow
          canvas.drawLine(
            c + Offset(-s * 0.1, -s * 0.12 + side * s * 0.03),
            c + Offset(s * 0.1, -s * 0.12 - side * s * 0.03),
            Paint()
              ..color = AppColors.leafDark
              ..strokeWidth = s * 0.03
              ..strokeCap = StrokeCap.round,
          );
        case MascotMood.sleepy:
          canvas.drawArc(
            Rect.fromCenter(center: c, width: s * 0.14, height: s * 0.08),
            0,
            math.pi,
            false,
            Paint()
              ..color = const Color(0xFF2B3A45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.025
              ..strokeCap = StrokeCap.round,
          );
      }
    }

    // Beak
    final beak = Path()
      ..moveTo(cx - s * 0.06, s * 0.53)
      ..lineTo(cx + s * 0.06, s * 0.53)
      ..lineTo(cx, s * (mood == MascotMood.cheer ? 0.63 : 0.61))
      ..close();
    canvas.drawPath(beak, fill(AppColors.flame));

    // Feet
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * s * 0.12, s * 0.93),
          width: s * 0.14,
          height: s * 0.06,
        ),
        fill(AppColors.flame),
      );
    }

    if (mood == MascotMood.sleepy) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z z',
          style: TextStyle(
            fontSize: s * 0.13,
            fontWeight: FontWeight.w900,
            color: AppColors.sky.withValues(alpha: 0.5 + t * 0.5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + s * 0.26, s * (0.08 - t * 0.04)));
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.t != t || old.mood != mood;
}
