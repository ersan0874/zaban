import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/subscription_model.dart';
import 'package:zaban/services/subscription_service.dart';
import 'package:zaban/services/user_stats_service.dart';
import 'package:zaban/theme/app_theme.dart';

class SuperSubscriptionScreen extends StatefulWidget {
  const SuperSubscriptionScreen({super.key});

  @override
  State<SuperSubscriptionScreen> createState() =>
      _SuperSubscriptionScreenState();
}

class _SuperSubscriptionScreenState extends State<SuperSubscriptionScreen> {
  final SubscriptionService _service = subscriptionService;
  SuperPlan _selected = SuperPlan.threeMonths;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_service.fetchStatus());
  }

  Future<void> _upgrade() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payment = await _service.requestPayment(_selected);

      if (!mounted) return;
      setState(() => _loading = false);

      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'پرداخت Super',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'نسخه آزمایشی: می‌توانید پرداخت را شبیه‌سازی کنید یا لینک درگاه را باز کنید.',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(height: 1.6),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text('انصراف', style: GoogleFonts.vazirmatn()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'browser'),
              child: Text('باز کردن درگاه', style: GoogleFonts.vazirmatn()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'mock'),
              style: AppTheme.chunkyStyle(
                face: AppColors.sun,
                edge: AppColors.sunDark,
                foreground: AppColors.ink,
              ),
              child: Text(
                'شبیه‌سازی پرداخت',
                style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );

      if (!mounted || choice == null || choice == 'cancel') return;

      setState(() => _loading = true);

      if (choice == 'mock') {
        await _service.completeMockPayment(payment.authority);
      } else {
        final url = _service.resolvePaymentUrl(payment);
        final launched = await _service.openPaymentUrl(url);
        if (!launched) {
          // Fallback to API mock if browser cannot open
          await _service.completeMockPayment(payment.authority);
        } else {
          await _service.refreshAfterPayment();
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);

      if (_service.isActive || userStatsService.isSuper) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.leafDark,
            content: Text(
              'Super فعال شد! قلب بی‌نهایت داری ♾️',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error =
              'هنوز اشتراک فعال نیست. اگر در مرورگر پرداخت کردی، دوباره تلاش کن.';
        });
      }
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
    return Scaffold(
      body: Container(
        color: const Color(0xFF1C2833),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: _service,
                      builder: (context, _) {
                        if (!_service.isActive) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sun.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.sun),
                          ),
                          child: Text(
                            'Super فعال',
                            style: GoogleFonts.vazirmatn(
                              color: AppColors.sun,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.grape, AppColors.sky],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.all_inclusive_rounded,
                                color: Colors.white, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'Super',
                              style: GoogleFonts.nunito(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'قلب بی‌نهایت · بدون محدودیت',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.vazirmatn(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _FeatureChip(label: 'قلب نامحدود'),
                                _FeatureChip(label: 'بدون وقفه یادگیری'),
                                _FeatureChip(label: 'پشتیبانی اولویت‌دار'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      ...SuperPlan.values.map((plan) {
                        final selected = _selected == plan;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            selected: selected,
                            onTap: () => setState(() => _selected = plan),
                          ),
                        );
                      }),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.vazirmatn(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _upgrade,
                          style: AppTheme.chunkyStyle(
                            face: AppColors.sun,
                            edge: AppColors.sunDark,
                            foreground: AppColors.ink,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.ink,
                                  ),
                                )
                              : Text(
                                  'ارتقا به Super',
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'پرداخت از طریق درگاه امن (نسخه آزمایشی Mock)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.vazirmatn(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SuperPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? AppColors.sky.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? AppColors.sky
                  : Colors.white.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.sky : Colors.white54,
                    width: 2,
                  ),
                  color: selected ? AppColors.sky : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (plan.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grape,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              plan.badge!,
                              style: GoogleFonts.vazirmatn(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.subtitle,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.sun,
                    ),
                  ),
                  Text(
                    'تومان',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
