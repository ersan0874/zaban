import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/user_stats_model.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/user_stats_service.dart';
import 'package:zaban/theme/app_theme.dart';

Future<void> showShopBottomSheet(
  BuildContext context, {
  UserStatsService? statsService,
  String? message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (context) => ShopBottomSheet(
      statsService: statsService ?? userStatsService,
      message: message,
    ),
  );
}

class ShopBottomSheet extends StatefulWidget {
  const ShopBottomSheet({
    super.key,
    required this.statsService,
    this.message,
  });

  final UserStatsService statsService;
  final String? message;

  @override
  State<ShopBottomSheet> createState() => _ShopBottomSheetState();
}

class _ShopBottomSheetState extends State<ShopBottomSheet> {
  bool _loading = false;
  String? _error;

  UserStatsModel? get _stats => widget.statsService.stats;

  Future<void> _refill() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.statsService.refillHearts();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'قلب‌ها ترمیم شد!',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final hearts = stats?.hearts ?? 0;
    final gems = stats?.gems ?? 0;
    final canAfford = gems >= UserStatsModel.refillCost;
    final full = hearts >= UserStatsModel.maxHearts;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mistDeep,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'فروشگاه',
            style: GoogleFonts.vazirmatn(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                color: AppColors.slate,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(emoji: '❤️', label: '$hearts'),
              const SizedBox(width: 12),
              _StatChip(emoji: '💎', label: '$gems'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Column(
              children: [
                const Text('❤️❤️❤️❤️❤️', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 10),
                Text(
                  'ترمیم کامل قلب‌ها',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '۵ قلب در ازای ۵۰ جم',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_loading || full || !canAfford) ? null : _refill,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      full
                          ? 'قلب‌ها پر هستند'
                          : !canAfford
                              ? 'جم کافی نیست'
                              : 'ترمیم قلب‌ها (۵۰ جم)',
                      style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SuperSubscriptionScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
              child: Text(
                'ارتقا به Super — قلب بی‌نهایت ♾️',
                style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.mistDeep),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
