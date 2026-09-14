import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/gamification_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/screens/shop/shop_screen.dart';
import 'package:zaban/theme/app_theme.dart';

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
            ? Center(
                child: Text(_error!, style: GoogleFonts.vazirmatn()),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'XP',
                          value: '${g?.xp ?? 0}',
                          color: AppColors.tealDeep,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'استریک',
                          value: '${g?.streakCount ?? 0}',
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'قلب',
                          value: '${g?.hearts ?? 0}/${g?.heartsCap ?? 5}',
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      g?.clubUnlocked == true
                          ? 'باشگاه باز است ✓'
                          : 'باشگاه هنوز قفل است (استریک ۷ یا ۵۰۰ XP)',
                      style: GoogleFonts.vazirmatn(color: AppColors.slate),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'کوئست روزانه',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...?(g?.quests.map((q) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.mistDeep),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.title,
                                    style: GoogleFonts.vazirmatn(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${q.progress}/${q.target}',
                                    style: GoogleFonts.vazirmatn(
                                      color: AppColors.slate,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              q.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: q.completed
                                  ? AppColors.success
                                  : AppColors.locked,
                            ),
                          ],
                        ),
                      );
                    })),
                    const SizedBox(height: 16),
                    Text(
                      'نشان‌ها',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((g?.badges ?? []).isEmpty)
                      Text(
                        'هنوز نشانی نداری — یک درس تمام کن.',
                        style: GoogleFonts.vazirmatn(color: AppColors.slate),
                      )
                    else
                      ...g!.badges.map(
                        (b) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            b.title,
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            b.pinned ? 'پین شده روی پروفایل' : b.badgeKey,
                            style: GoogleFonts.vazirmatn(fontSize: 12),
                          ),
                          trailing: IconButton(
                            onPressed: () => _togglePin(b),
                            icon: Icon(
                              b.pinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: AppColors.tealDeep,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'جعبه جایزه',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((g?.lootBoxes ?? []).isEmpty)
                      Text(
                        'هر ۳ درس یک جعبه می‌گیری.',
                        style: GoogleFonts.vazirmatn(color: AppColors.slate),
                      )
                    else
                      ...g!.lootBoxes.map(
                        (box) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'جعبه بسته',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: FilledButton(
                            onPressed:
                                _opening ? null : () => _openLoot(box.id),
                            child: Text(
                              'باز کن',
                              style: GoogleFonts.vazirmatn(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );

    if (widget.embedded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(color: AppColors.mist, child: body),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mist,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mistDeep),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.vazirmatn(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.vazirmatn(fontSize: 12, color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}
