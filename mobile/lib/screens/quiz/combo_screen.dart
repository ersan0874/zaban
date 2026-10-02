import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/services/feedback_fx.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/confetti.dart';
import 'package:zaban/widgets/mascot.dart';

/// Full-screen reward after 5, 10, 15, ... pages in a row without a
/// mistake. Each tier looks (and pays) bigger than the last.
class ComboScreen extends StatefulWidget {
  const ComboScreen({super.key, required this.reward});

  final ComboReward reward;

  static Future<void> show(BuildContext context, ComboReward reward) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => ComboScreen(reward: reward),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  State<ComboScreen> createState() => _ComboScreenState();
}

class _ComboScreenState extends State<ComboScreen> {
  @override
  void initState() {
    super.initState();
    FeedbackFx.instance.play(Fx.combo);
  }

  ({String title, Color bg, Color edge, Color soft}) get _look {
    final tier = widget.reward.tier;
    if (tier >= 3) {
      return (
        title: 'کومبوی افسانه‌ای!',
        bg: AppColors.grape,
        edge: AppColors.grapeDark,
        soft: const Color(0xFFF1E8FF),
      );
    }
    if (tier == 2) {
      return (
        title: 'سوپر کومبو!',
        bg: AppColors.flame,
        edge: const Color(0xFFE07F00),
        soft: const Color(0xFFFFEBD3),
      );
    }
    return (
      title: 'کومبو!',
      bg: AppColors.sun,
      edge: AppColors.sunDark,
      soft: AppColors.sunSoft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final look = _look;
    final next = r.streak + 5;
    return Scaffold(
      backgroundColor: look.bg,
      body: Stack(
        children: [
          Positioned.fill(child: Confetti(count: 60 + r.tier * 30)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  const Mascot(mood: MascotMood.cheer, size: 170),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Text(
                      look.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: look.edge, offset: const Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${r.streak} صفحه پشت سر هم بدون اشتباه',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: look.edge,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.sky,
                            size: 40,
                          ),
                          const SizedBox(width: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '+${r.energyAwarded}',
                              style: AppTheme.latin(
                                fontSize: 36,
                                color: AppColors.skyDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'انرژی',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.skyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'تا $next بی‌اشتباه برو؛ جایزه بزرگ‌تر می‌شود!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppTheme.chunkyStyle(
                        face: Colors.white,
                        edge: look.edge,
                        foreground: look.edge,
                        textStyle: GoogleFonts.vazirmatn(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ادامه'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
