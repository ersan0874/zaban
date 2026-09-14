import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/user_stats_service.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/shop_bottom_sheet.dart';

class StatsHeaderBar extends StatelessWidget {
  const StatsHeaderBar({
    super.key,
    required this.statsService,
    this.shakeHearts = false,
  });

  final UserStatsService statsService;
  final bool shakeHearts;

  void _openSuper(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SuperSubscriptionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: statsService,
      builder: (context, _) {
        final hearts = statsService.hearts;
        final gems = statsService.gems;
        final streak = statsService.streak;
        final isSuper = statsService.isSuper;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatBadge(
              emoji: '🔥',
              value: '$streak',
              onTap: () => isSuper
                  ? _openSuper(context)
                  : showShopBottomSheet(context, statsService: statsService),
            ),
            const SizedBox(width: 10),
            TweenAnimationBuilder<double>(
              key: ValueKey('${shakeHearts}_$isSuper'),
              tween: Tween(begin: 0, end: shakeHearts ? 1 : 0),
              duration: const Duration(milliseconds: 450),
              builder: (context, t, child) {
                final dx = shakeHearts
                    ? (t < 0.5
                        ? (t * 4 - 1) * 6
                        : ((1 - t) * 4 - 1) * 6)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: isSuper
                  ? _SuperHeartBadge(onTap: () => _openSuper(context))
                  : _StatBadge(
                      emoji: '❤️',
                      value: '$hearts',
                      highlight: hearts <= 0,
                      onTap: () => showShopBottomSheet(
                        context,
                        statsService: statsService,
                        message: hearts <= 0 ? 'قلب‌هایت تمام شده!' : null,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            _StatBadge(
              emoji: '💎',
              value: '$gems',
              onTap: () => isSuper
                  ? _openSuper(context)
                  : showShopBottomSheet(context, statsService: statsService),
            ),
          ],
        );
      },
    );
  }
}

class _SuperHeartBadge extends StatelessWidget {
  const _SuperHeartBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(
                '♾️',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'SUPER',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: const Color(0xFF1A0B2E),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.emoji,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final String emoji;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFFFEE2E2)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: highlight ? AppColors.danger : AppColors.mistDeep,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: highlight ? AppColors.danger : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
