import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/progress_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

/// Shows skill scores + due SRS review queue from the server.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repo = ProgressRepository();
  bool _loading = true;
  String? _error;
  ProgressSummary? _summary;
  ReviewsQueue? _reviews;

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
      final summary = await _repo.getProgress();
      final reviews = await _repo.getReviews();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _reviews = reviews;
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
        _error = 'بارگذاری پیشرفت ناموفق بود';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          title: Text(
            'پیشرفت و مرور',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vazirmatn(),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: Text(
                              'تلاش دوباره',
                              style: GoogleFonts.vazirmatn(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        _StatRow(
                          tracked: _summary?.totalTracked ?? 0,
                          due: _summary?.dueCount ?? 0,
                          avg: _summary?.averageSkillScore ?? 0,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'صف مرور سررسید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((_reviews?.items ?? []).isEmpty)
                          Text(
                            'الان چیزی برای مرور فوری نیست. بعد از غلط‌ها اینجا پر می‌شود.',
                            style: GoogleFonts.vazirmatn(
                              color: AppColors.slate,
                            ),
                          )
                        else
                          ..._reviews!.items.map(
                            (item) => _ProgressTile(item: item, highlight: true),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'همه مهارت‌ها',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((_summary?.items ?? []).isEmpty)
                          Text(
                            'هنوز تمرینی ثبت نشده. یک آزمون بده تا مهارت‌ها اینجا بیایند.',
                            style: GoogleFonts.vazirmatn(
                              color: AppColors.slate,
                            ),
                          )
                        else
                          ..._summary!.items.map(
                            (item) => _ProgressTile(item: item),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.tracked,
    required this.due,
    required this.avg,
  });

  final int tracked;
  final int due;
  final int avg;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.vazirmatn(
                  fontSize: 12,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('پیگیری', '$tracked', AppColors.tealDeep),
        const SizedBox(width: 8),
        chip('سررسید', '$due', AppColors.amber),
        const SizedBox(width: 8),
        chip('میانگین', '$avg', AppColors.ink),
      ],
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.item, this.highlight = false});

  final ProgressItem item;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.amberSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.amber.withValues(alpha: 0.4) : AppColors.mistDeep,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label?.isNotEmpty == true
                      ? item.label!
                      : '${item.itemKind} · ${item.itemId.substring(0, 8)}',
                  style: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'درست ${item.totalCorrect} · غلط ${item.totalIncorrect}'
                  '${item.isDue ? ' · الان مرور کن' : ''}',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.skillScore}',
            style: GoogleFonts.vazirmatn(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.tealDeep,
            ),
          ),
        ],
      ),
    );
  }
}
