import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/late_grades_repository.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/math_text.dart';

/// Shows essay grades that arrived after the lesson, then marks them seen.
Future<void> showLateGradesIfAny(
  BuildContext context, {
  LateGradesRepository? repository,
}) async {
  final repo = repository ?? LateGradesRepository();
  List<LateGradeNotice> notices;
  try {
    notices = await repo.listUnseen();
  } catch (_) {
    return; // Not important enough to bother the learner with an error.
  }
  if (notices.isEmpty || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.snow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => LateGradesSheet(notices: notices),
  );
  try {
    await repo.markSeen(notices.map((n) => n.attemptId).toList());
  } catch (_) {
    // Shown again next time; harmless.
  }
}

class LateGradesSheet extends StatelessWidget {
  const LateGradesSheet({super.key, required this.notices});

  final List<LateGradeNotice> notices;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.grape,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'نمره پاسخ‌های تشریحی‌ات رسید',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NoticeCard(notice: notices[i]),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final LateGradeNotice notice;

  @override
  Widget build(BuildContext context) {
    final color = notice.isCorrect ? AppColors.leaf : AppColors.coral;
    final soft = notice.isCorrect ? AppColors.leafSoft : AppColors.coralSoft;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notice.lessonTitle,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
              if (notice.score != null)
                Text(
                  '${(notice.score! * 100).round()}%',
                  style: AppTheme.latin(fontSize: 18, color: color),
                ),
            ],
          ),
          const SizedBox(height: 6),
          MathText(
            notice.question,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if ((notice.feedback ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(
              notice.feedback!.trim(),
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
