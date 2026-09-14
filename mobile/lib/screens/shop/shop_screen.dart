import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/billing_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _repo = BillingRepository();
  bool _loading = true;
  String? _error;
  BillingSnapshot? _data;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getMe();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _buy(String productId, String label) async {
    setState(() => _buying = true);
    try {
      final receipt =
          'TEST.${DateTime.now().millisecondsSinceEpoch}.$productId';
      await _repo.verifyPurchase(productId: productId, receipt: receipt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label با موفقیت خریداری شد',
            style: GoogleFonts.vazirmatn(),
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.vazirmatn())),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _data?.subscription;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          title: Text(
            'فروشگاه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: GoogleFonts.vazirmatn()))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (sub != null && sub.active)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'اشتراک نامحدود فعال تا ${sub.expiresAt.toLocal()}',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _ProductTile(
                        title: 'بسته انرژی (+10)',
                        subtitle: 'energy_pack_10',
                        onBuy: _buying
                            ? null
                            : () => _buy('energy_pack_10', 'بسته انرژی'),
                      ),
                      _ProductTile(
                        title: 'انرژی نامحدود — ۱ روز',
                        subtitle: 'unlimited_1d',
                        onBuy: _buying
                            ? null
                            : () => _buy('unlimited_1d', 'اشتراک ۱ روزه'),
                      ),
                      _ProductTile(
                        title: 'انرژی نامحدود — ۱ هفته',
                        subtitle: 'unlimited_1w',
                        onBuy: _buying
                            ? null
                            : () => _buy('unlimited_1w', 'اشتراک ۱ هفته'),
                      ),
                      _ProductTile(
                        title: 'انرژی نامحدود — ۱ ماه',
                        subtitle: 'unlimited_1m',
                        onBuy: _buying
                            ? null
                            : () => _buy('unlimited_1m', 'اشتراک ۱ ماه'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'خریدهای اخیر',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...?(_data?.purchases.take(5).map(
                            (p) => ListTile(
                              title: Text(
                                p.productId,
                                style: GoogleFonts.vazirmatn(),
                              ),
                              subtitle: Text(
                                p.status,
                                style: GoogleFonts.vazirmatn(fontSize: 12),
                              ),
                            ),
                          )),
                    ],
                  ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.title,
    required this.subtitle,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: GoogleFonts.vazirmatn()),
        subtitle: Text(subtitle, style: GoogleFonts.vazirmatn(fontSize: 12)),
        trailing: ElevatedButton(
          onPressed: onBuy,
          child: Text('خرید تست', style: GoogleFonts.vazirmatn()),
        ),
      ),
    );
  }
}
