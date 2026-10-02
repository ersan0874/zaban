import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/billing_repository.dart';
import 'package:zaban/repositories/economy_repository.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

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
            ? ZMessage(
                icon: Icons.storefront_outlined,
                text: _error!,
                actionLabel: 'تلاش دوباره',
                onAction: _load,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    ZBanner(
                      title: '$_gems جم',
                      subtitle: 'با جم قلب، انرژی و فریز استریک بخر',
                      color: AppColors.grape,
                      edge: AppColors.grapeDark,
                      icon: Icons.diamond_rounded,
                    ),
                    const SizedBox(height: 12),
                    ZCard(
                      color: AppColors.ink,
                      borderColor: AppColors.ink,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SuperSubscriptionScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.grape, AppColors.sky],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SUPER',
                              style: AppTheme.latin(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'قلب نامحدود و امکانات ویژه',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    if (sub != null && sub.active) ...[
                      const SizedBox(height: 12),
                      ZCard(
                        color: AppColors.leafSoft,
                        borderColor: AppColors.leaf,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'اشتراک انرژی نامحدود فعال است',
                          style: GoogleFonts.vazirmatn(
                            fontWeight: FontWeight.w700,
                            color: AppColors.leafDark,
                          ),
                        ),
                      ),
                    ],
                    const ZSectionTitle('خرید با جم'),
                    if (_gemItems.isEmpty)
                      Text(
                        'آیتم فروشگاهی موجود نیست.',
                        style: GoogleFonts.vazirmatn(color: AppColors.slate),
                      )
                    else
                      ..._gemItems.map(
                        (item) => _ShopTile(
                          icon: _iconFor(item.effectType),
                          color: _colorFor(item.effectType),
                          title: item.title,
                          subtitle:
                              '${item.description} · ${item.priceGems} جم',
                          actionLabel: 'خرید',
                          onBuy: _buying ? null : () => _buyGems(item),
                        ),
                      ),
                    const ZSectionTitle('خرید تستی (پول واقعی)'),
                    _ShopTile(
                      icon: Icons.bolt_rounded,
                      color: AppColors.sky,
                      title: 'بسته انرژی (+10)',
                      subtitle: 'energy_pack_10',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('energy_pack_10', 'بسته انرژی'),
                    ),
                    _ShopTile(
                      icon: Icons.all_inclusive_rounded,
                      color: AppColors.sky,
                      title: 'انرژی نامحدود — ۱ روز',
                      subtitle: 'unlimited_1d',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('unlimited_1d', 'اشتراک ۱ روزه'),
                    ),
                    _ShopTile(
                      icon: Icons.all_inclusive_rounded,
                      color: AppColors.sky,
                      title: 'انرژی نامحدود — ۱ هفته',
                      subtitle: 'unlimited_1w',
                      actionLabel: 'خرید تست',
                      onBuy: _buying
                          ? null
                          : () => _buyIap('unlimited_1w', 'اشتراک ۱ هفته'),
                    ),
                    _ShopTile(
                      icon: Icons.all_inclusive_rounded,
                      color: AppColors.sky,
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
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onBuy,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return ZCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
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
          const SizedBox(width: 8),
          FilledButton(onPressed: onBuy, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

IconData _iconFor(String effectType) {
  if (effectType.contains('freeze')) return Icons.ac_unit_rounded;
  if (effectType.contains('heart')) return Icons.favorite_rounded;
  if (effectType.contains('energy')) return Icons.bolt_rounded;
  return Icons.card_giftcard_rounded;
}

Color _colorFor(String effectType) {
  if (effectType.contains('freeze')) return AppColors.sky;
  if (effectType.contains('heart')) return AppColors.coral;
  if (effectType.contains('energy')) return AppColors.sun;
  return AppColors.grape;
}
