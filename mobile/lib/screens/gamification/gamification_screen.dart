import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/gamification_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/screens/shop/shop_screen.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final _repo = GamificationRepository();
  bool _loading = true;
  String? _error;
  GamificationSnapshot? _data;
  bool _opening = false;

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
      final data = await _repo.getSnapshot();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'بارگذاری گیمیفیکیشن ناموفق بود';
      });
    }
  }

  Future<void> _openLoot(String id) async {
    setState(() => _opening = true);
    try {
      final result = await _repo.openLoot(id);
      if (!mounted) return;
      final rewards = result['rewards'] as Map?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rewards == null
                ? 'جعبه باز شد'
                : 'جایزه: XP ${rewards['xp'] ?? 0} · انرژی ${rewards['energy'] ?? 0} · فریز ${rewards['streakFreeze'] ?? 0}',
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
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _togglePin(BadgeItem badge) async {
    try {
      await _repo.pinBadge(badge.badgeKey, pinned: !badge.pinned);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.vazirmatn())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _data;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ZMessage(
                icon: Icons.cloud_off_rounded,
                text: _error!,
                actionLabel: 'تلاش دوباره',
                onAction: _load,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.4,
                      children: [
                        ZStatTile(
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.flame,
                          value: '${g?.streakCount ?? 0}',
                          label: 'روز استریک',
                        ),
                        ZStatTile(
                          icon: Icons.bolt_rounded,
                          color: AppColors.sun,
                          value: '${g?.xp ?? 0}',
                          label: 'XP کل',
                        ),
                        ZStatTile(
                          icon: Icons.favorite_rounded,
                          color: AppColors.coral,
                          value: '${g?.hearts ?? 0}/${g?.heartsCap ?? 5}',
                          label: 'قلب',
                        ),
                        ZStatTile(
                          icon: Icons.school_rounded,
                          color: AppColors.leaf,
                          value: '${g?.lessonsCompleted ?? 0}',
                          label: 'درس تمام‌شده',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ZCard(
                      color: g?.clubUnlocked == true
                          ? AppColors.leafSoft
                          : AppColors.mist,
                      borderColor: g?.clubUnlocked == true
                          ? AppColors.leaf
                          : AppColors.line,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            g?.clubUnlocked == true
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            color: g?.clubUnlocked == true
                                ? AppColors.leafDark
                                : AppColors.locked,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              g?.clubUnlocked == true
                                  ? 'باشگاه برایت باز است'
                                  : 'باشگاه با ۷ روز استریک یا ۵۰۰ XP باز می‌شود',
                              style: GoogleFonts.vazirmatn(
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ZSectionTitle('کوئست‌های روزانه'),
                    ZCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, q) in (g?.quests ?? []).indexed) ...[
                            if (i > 0)
                              const Divider(height: 2, color: AppColors.line),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    q.completed
                                        ? Icons.check_circle_rounded
                                        : Icons.bolt_rounded,
                                    color: q.completed
                                        ? AppColors.leaf
                                        : AppColors.sun,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.title,
                                          style: GoogleFonts.vazirmatn(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ZProgressBar(
                                                value: q.target == 0
                                                    ? 0
                                                    : q.progress / q.target,
                                                color: q.completed
                                                    ? AppColors.leaf
                                                    : AppColors.sun,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${q.progress}/${q.target}',
                                              style: AppTheme.latin(
                                                fontSize: 13,
                                                color: AppColors.slate,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if ((g?.quests ?? []).isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'کوئست امروز هنوز آماده نیست.',
                                style: GoogleFonts.vazirmatn(
                                  color: AppColors.slate,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const ZSectionTitle('جعبه‌های جایزه'),
                    if ((g?.lootBoxes ?? []).isEmpty)
                      ZCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: AppColors.locked,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'هر ۳ درس یک جعبه جایزه می‌گیری.',
                                style: GoogleFonts.vazirmatn(
                                  color: AppColors.slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...g!.lootBoxes.map(
                        (box) => ZCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: AppColors.sunSoft,
                          borderColor: AppColors.sun,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_giftcard_rounded,
                                color: AppColors.sunDark,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'یک جعبه جایزه داری!',
                                  style: GoogleFonts.vazirmatn(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: AppTheme.chunkyStyle(
                                  face: AppColors.sun,
                                  edge: AppColors.sunDark,
                                  foreground: AppColors.ink,
                                ),
                                onPressed:
                                    _opening ? null : () => _openLoot(box.id),
                                child: const Text('باز کن'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const ZSectionTitle('نشان‌ها'),
                    if ((g?.badges ?? []).isEmpty)
                      ZCard(
                        child: Text(
                          'هنوز نشانی نداری. یک درس تمام کن.',
                          style: GoogleFonts.vazirmatn(color: AppColors.slate),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: g!.badges
                            .map(
                              (b) => _BadgeChip(
                                badge: b,
                                onTap: () => _togglePin(b),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );

    if (widget.embedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(color: AppColors.snow, child: body),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'پیشرفت بازی',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShopScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.storefront_outlined),
              tooltip: 'فروشگاه',
            ),
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: body,
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.onTap});

  final BadgeItem badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: ZCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        borderColor: badge.pinned ? AppColors.grape : AppColors.line,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badge.pinned ? AppColors.grape : AppColors.sun,
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.pinned
                    ? Icons.push_pin_rounded
                    : Icons.military_tech_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.vazirmatn(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
