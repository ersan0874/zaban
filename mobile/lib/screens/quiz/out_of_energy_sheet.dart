import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/energy_repository.dart';
import 'package:zaban/screens/shop/shop_screen.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/mascot.dart';

/// Shown mid-lesson when the next page cannot be paid for. Returns true
/// once energy is back (regen or shop), false if the learner quits.
class OutOfEnergySheet extends StatefulWidget {
  const OutOfEnergySheet({super.key, this.energy});

  final EnergySnapshot? energy;

  static Future<bool> show(BuildContext context, EnergySnapshot? energy) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => OutOfEnergySheet(energy: energy),
    );
    return ok ?? false;
  }

  @override
  State<OutOfEnergySheet> createState() => _OutOfEnergySheetState();
}

class _OutOfEnergySheetState extends State<OutOfEnergySheet> {
  final _repo = EnergyRepository();
  late DateTime? _nextAt = _computeNext(widget.energy);
  Timer? _ticker;
  bool _checking = false;
  String? _note;

  DateTime? _computeNext(EnergySnapshot? e) {
    final ms = e?.millisUntilNextRegen;
    return ms == null ? null : DateTime.now().add(Duration(milliseconds: ms));
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final next = _nextAt;
      if (next != null && DateTime.now().isAfter(next) && !_checking) {
        _refresh(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool auto = false}) async {
    setState(() {
      _checking = true;
      _note = null;
    });
    try {
      final e = await _repo.getEnergy();
      if (!mounted) return;
      if (!e.isEmpty) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _nextAt = _computeNext(e);
        if (!auto) _note = 'هنوز شارژ نشده؛ کمی صبر کن.';
      });
    } catch (_) {
      if (mounted && !auto) {
        setState(() => _note = 'اتصال برقرار نشد؛ دوباره امتحان کن.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String get _countdown {
    final next = _nextAt;
    if (next == null) return '';
    final left = next.difference(DateTime.now());
    if (left.isNegative) return '00:00';
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Mascot(mood: MascotMood.sleepy, size: 120)),
            const SizedBox(height: 12),
            Text(
              'انرژی‌ات تمام شد!',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هر صفحه یک انرژی می‌خواهد. پیشرفتت در این درس سر جایش می‌ماند.',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            if (_countdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.skyBorder, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.sky),
                    const SizedBox(width: 6),
                    Text(
                      'انرژی بعدی تا',
                      style: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.w800,
                        color: AppColors.skyDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _countdown,
                        style: AppTheme.latin(
                          fontSize: 18,
                          color: AppColors.skyDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_note != null) ...[
              const SizedBox(height: 10),
              Text(
                _note!,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(color: AppColors.coralDark),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: AppTheme.chunkyStyle(
                face: AppColors.sky,
                edge: AppColors.skyDark,
                foreground: Colors.white,
                textStyle: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                );
                if (mounted) await _refresh();
              },
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('شارژ از فروشگاه'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _checking ? null : () => _refresh(),
              child: Text(_checking ? 'در حال بررسی…' : 'دوباره بررسی کن'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'خروج از درس',
                style: GoogleFonts.vazirmatn(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
