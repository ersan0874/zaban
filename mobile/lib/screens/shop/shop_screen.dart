import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/billing_repository.dart';
import 'package:zaban/repositories/economy_repository.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _billing = BillingRepository();
  final _economy = EconomyRepository();
  bool _loading = true;
  String? _error;
  BillingSnapshot? _billingData;
  List<ShopCatalogItem> _gemItems = const [];
  int _gems = 0;
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
      final billing = await _billing.getMe();
      var gems = 0;
      List<ShopCatalogItem> items = const [];
      try {
        gems = (await _economy.getWallet()).gems;
        items = await _economy.listShop();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _billingData = billing;
        _gems = gems;
        _gemItems = items;
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

  Future<void> _buyGems(ShopCatalogItem item) async {
    setState(() => _buying = true);
    try {
      await _economy.buyShopItem(item.key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} خریداری شد',
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

  Future<void> _buyIap(String productId, String label) async {
    setState(() => _buying = true);
    try {
      final receipt =
          'TEST.${DateTime.now().millisecondsSinceEpoch}.$productId';
      await _billing.verifyPurchase(productId: productId, receipt: receipt);
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
    final sub = _billingData?.subscription;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: GoogleFonts.vazirmatn()))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.diamond_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'موجودی جم: $_gems',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const SuperSubscriptionScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'زبان Super',
                                      style: GoogleFonts.vazirmatn(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'قلب نامحدود و امکانات ویژه',
                                      style: GoogleFonts.vazirmatn(
                                        color: AppColors.inkSoft,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (sub != null && sub.active) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'خرید با جم',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_gemItems.isEmpty)
                      Text(
                        'آیتم فروشگاهی موجود نیست.',
                        style: GoogleFonts.vazirmatn(color: AppColors.slate),
                      )
                    else
                      ..._gemItems.map(
                        (item) => _ShopTile(
                          title: item.title,
                          subtitle:
                              '${item.description} · ${item.priceGems} جم',
                          actionLabel: 'خرید',
                          onBuy: _buying ? null : () => _buyGems(item),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'خرید تستی (پول واقعی)',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ShopTile(
                      title: 'بسته انرژی (+10)',
                      subtitle: 'energy_pack_10',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('energy_pack_10', 'بسته انرژی'),
                    ),
                    _ShopTile(
                      title: 'انرژی نامحدود — ۱ روز',
                      subtitle: 'unlimited_1d',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('unlimited_1d', 'اشتراک ۱ روزه'),
                    ),
                    _ShopTile(
                      title: 'انرژی نامحدود — ۱ هفته',
                      subtitle: 'unlimited_1w',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('unlimited_1w', 'اشتراک ۱ هفته'),
                    ),
                    _ShopTile(
                      title: 'انرژی نامحدود — ۱ ماه',
                      subtitle: 'unlimited_1m',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('unlimited_1m', 'اشتراک ۱ ماه'),
                    ),
                  ],
                ),
              );

    if (widget.embedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: body,
      );
    }

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
        body: body,
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mistDeep),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBuy,
            child: Text(actionLabel, style: GoogleFonts.vazirmatn()),
          ),
        ],
      ),
    );
  }
}
