import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/curriculum_repository.dart';
import 'package:zaban/repositories/mastery_repository.dart';
import 'package:zaban/repositories/progress_repository.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

/// Shows skill scores + due SRS review queue from the server.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _repo = ProgressRepository();
  final _curriculum = CurriculumRepository();
  final _mastery = MasteryRepository();
  bool _loading = true;
  String? _error;
  ProgressSummary? _summary;
  ReviewsQueue? _reviews;
  double? _masteryScore;

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
      double? mastery;
      try {
        final courses = await _curriculum.listCourses();
        if (courses.isNotEmpty) {
          mastery = (await _mastery.getCourseMastery(courses.first.id)).score;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _reviews = reviews;
        _masteryScore = mastery;
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
        appBar: AppBar(
          title: const Text('پیشرفت و مرور'),
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
                ? ZMessage(
                    icon: Icons.insights_rounded,
                    text: _error!,
                    actionLabel: 'تلاش دوباره',
                    onAction: _load,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        if (_masteryScore != null) ...[
                          ZBanner(
                            title: 'تسلط دوره ${_masteryScore!.round()}%',
                            subtitle: 'هر چه بیشتر مرور کنی، بالاتر می‌رود',
                            color: AppColors.sky,
                            edge: AppColors.skyDark,
                            icon: Icons.insights_rounded,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor:
                                    (_masteryScore! / 100).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _StatRow(
                          tracked: _summary?.totalTracked ?? 0,
                          due: _summary?.dueCount ?? 0,
                          avg: _summary?.averageSkillScore ?? 0,
                        ),
                        const ZSectionTitle('وقت مرور است'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'این واژه‌ها در درس بعدی برای مرور می‌آیند.',
                            style: GoogleFonts.vazirmatn(
                              color: AppColors.slate,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if ((_reviews?.items ?? []).isEmpty)
                          Text(
                            'الان چیزی برای مرور فوری نیست. بعد از غلط‌ها اینجا پر می‌شود.',
                            style: GoogleFonts.vazirmatn(
                              color: AppColors.slate,
                            ),
                          )
                        else
                          ..._reviews!.items.map(
                            (item) =>
                                _ProgressTile(item: item, highlight: true),
                          ),
                        const ZSectionTitle('همه مهارت‌ها'),
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
    return Row(
      children: [
        Expanded(
          child: ZStatTile(
            icon: Icons.menu_book_rounded,
            color: AppColors.leaf,
            value: '$tracked',
            label: 'واژه',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ZStatTile(
            icon: Icons.replay_rounded,
            color: AppColors.flame,
            value: '$due',
            label: 'مرور',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ZStatTile(
            icon: Icons.star_rounded,
            color: AppColors.sun,
            value: '$avg',
            label: 'میانگین',
          ),
        ),
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
    final color = item.skillScore >= 70
        ? AppColors.leaf
        : item.skillScore >= 40
            ? AppColors.sun
            : AppColors.coral;
    return ZCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      color: highlight ? AppColors.sunSoft : AppColors.snow,
      borderColor: highlight ? AppColors.sun : AppColors.line,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (item.skillScore / 100).clamp(0.0, 1.0),
                  strokeWidth: 5,
                  color: color,
                  backgroundColor: AppColors.line,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${item.skillScore}',
                  style: AppTheme.latin(fontSize: 14, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label?.isNotEmpty == true
                      ? item.label!
                      : '${item.itemKind} · ${item.itemId.substring(0, 8)}',
                  style: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}
