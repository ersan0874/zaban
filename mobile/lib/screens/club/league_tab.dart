import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/economy_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: GoogleFonts.vazirmatn()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: Text('تلاش دوباره', style: GoogleFonts.vazirmatn()),
              ),
            ],
          ),
        ),
      );
    }

    final tier = _tierFa(_current?.tier ?? _board?.tier ?? 'bronze');
    final xp = _current?.weeklyXp ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لیگ هفتگی · $tier',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'XP این هفته: $xp',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'رتبه‌بندی',
            style: GoogleFonts.vazirmatn(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if ((_board?.entries ?? []).isEmpty)
            Text(
              'هنوز کسی در لیگ نیست — یک درس تمام کن.',
              style: GoogleFonts.vazirmatn(color: AppColors.slate),
            )
          else
            ..._board!.entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: e.isYou ? AppColors.tealSoft : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: e.isYou ? AppColors.teal : AppColors.mistDeep,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '#${e.rank}',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.isYou ? '${e.displayName} (تو)' : e.displayName,
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${e.weeklyXp} XP',
                      style: GoogleFonts.vazirmatn(
                        color: AppColors.tealDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
