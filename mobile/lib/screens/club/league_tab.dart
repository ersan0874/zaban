import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/economy_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

class LeagueTab extends StatefulWidget {
  const LeagueTab({super.key});

  @override
  State<LeagueTab> createState() => _LeagueTabState();
}

class _LeagueTabState extends State<LeagueTab> {
  final _repo = EconomyRepository();
  bool _loading = true;
  String? _error;
  LeagueCurrent? _current;
  LeaderboardSnapshot? _board;

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
      final current = await _repo.getCurrentLeague();
      final board = await _repo.getLeaderboard();
      if (!mounted) return;
      setState(() {
        _current = current;
        _board = board;
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
        _error = 'بارگذاری لیگ ناموفق بود';
      });
    }
  }

  String _tierFa(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return 'نقره';
      case 'gold':
        return 'طلا';
      case 'platinum':
        return 'پلاتین';
      case 'diamond':
        return 'الماس';
      default:
        return 'برنز';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ZMessage(
        icon: Icons.shield_outlined,
        text: _error!,
        actionLabel: 'تلاش دوباره',
        onAction: _load,
      );
    }

    final tierKey = (_current?.tier ?? _board?.tier ?? 'bronze').toLowerCase();
    final tier = _tierFa(tierKey);
    final tierColor = _tierColor(tierKey);
    final xp = _current?.weeklyXp ?? 0;
    final entries = _board?.entries ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ZBanner(
            title: 'لیگ $tier',
            subtitle: 'این هفته $xp XP گرفتی',
            color: tierColor.$1,
            edge: tierColor.$2,
            icon: Icons.shield_rounded,
          ),
          const ZSectionTitle('جدول این هفته'),
          if (entries.isEmpty)
            ZCard(
              child: Text(
                'هنوز کسی در لیگ نیست. یک درس تمام کن تا اولین نفر باشی.',
                style: GoogleFonts.vazirmatn(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ZCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, e) in entries.indexed) ...[
                    if (i > 0) Divider(height: 2, color: AppColors.line),
                    Container(
                      color: e.isYou ? AppColors.skySoft : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${e.rank}',
                              textAlign: TextAlign.center,
                              style: AppTheme.latin(
                                fontSize: 16,
                                color: e.rank <= 3
                                    ? AppColors.sunDark
                                    : AppColors.slate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ZAvatar(name: e.displayName, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.isYou ? '${e.displayName} (تو)' : e.displayName,
                              style: GoogleFonts.vazirmatn(
                                fontWeight: FontWeight.w800,
                                color:
                                    e.isYou ? AppColors.skyDark : AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${e.weeklyXp} XP',
                            textDirection: TextDirection.ltr,
                            style: AppTheme.latin(
                              fontSize: 14,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color) _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return (const Color(0xFF9AA8B4), const Color(0xFF7A8996));
      case 'gold':
        return (AppColors.sun, AppColors.sunDark);
      case 'platinum':
        return (AppColors.sky, AppColors.skyDark);
      case 'diamond':
        return (AppColors.grape, AppColors.grapeDark);
      default:
        return (const Color(0xFFCD8B4E), const Color(0xFFA86B33));
    }
  }
}
