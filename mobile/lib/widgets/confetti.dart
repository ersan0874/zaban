import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zaban/theme/app_theme.dart';

/// One-shot confetti burst drawn over its child. No package needed.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 90, this.duration});

  final int count;
  final Duration? duration;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? const Duration(milliseconds: 2800),
  )..forward();

  late final List<_Piece> _pieces = List.generate(widget.count, (i) {
    final r = math.Random(i * 7919);
    const colors = [
      AppColors.leaf,
      AppColors.sky,
      AppColors.sun,
      AppColors.coral,
      AppColors.grape,
      AppColors.flame,
    ];
    return _Piece(
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.25,
      speed: 0.7 + r.nextDouble() * 0.6,
      drift: (r.nextDouble() - 0.5) * 0.3,
      spin: (r.nextDouble() - 0.5) * 14,
      size: 6 + r.nextDouble() * 6,
      color: colors[i % colors.length],
      round: r.nextBool(),
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x, delay, speed, drift, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * p.speed * (size.height + 60);
      final x = (p.x + p.drift * local + 0.03 * math.sin(local * 12 + p.spin)) *
          size.width;
      final fade = local > 0.85 ? (1 - local) / 0.15 : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.45,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
