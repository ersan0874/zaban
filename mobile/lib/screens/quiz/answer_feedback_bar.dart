import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/math_text.dart';

const _praise = ['آفرین!', 'عالی بود!', 'درسته!', 'دمت گرم!', 'محشره!'];

/// Bottom panel shown right after an answer: green when correct, red with
/// the right answer when wrong, blue when AI grading is still pending.
class AnswerFeedbackBar extends StatelessWidget {
  const AnswerFeedbackBar({
    super.key,
    required this.result,
    required this.onContinue,
    this.seed = 0,
  });

  final StepResult result;
  final VoidCallback onContinue;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final pending = !result.graded;
    final ok = result.isCorrect;
    final (Color soft, Color main, Color dark, IconData icon, String title) =
        pending
            ? (
                AppColors.skySoft,
                AppColors.sky,
                AppColors.skyDark,
                Icons.hourglass_top_rounded,
                result.gradingStatus == 'pending'
                    ? 'پاسخت ثبت شد؛ بعداً تصحیح می‌شود'
                    : 'تصحیح خودکار امروز در دسترس نیست',
              )
            : ok
                ? (
                    AppColors.leafSoft,
                    AppColors.leaf,
                    AppColors.leafDark,
                    Icons.check_rounded,
                    _praise[seed % _praise.length],
                  )
                : (
                    AppColors.coralSoft,
                    AppColors.coral,
                    AppColors.coralDark,
                    Icons.close_rounded,
                    'پاسخ درست:',
                  );

    final solution = result.solution?.trim() ?? '';
    final feedback = result.feedback?.trim() ?? '';
    final showSolution = !ok && solution.isNotEmpty;
    final essayScore =
        result.graded && result.score != null && feedback.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, v * 160),
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: soft,
          border: Border(top: BorderSide(color: main, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: main,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: dark,
                      ),
                    ),
                  ),
                  if (essayScore)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${(result.score! * 100).round()}%',
                        style: AppTheme.latin(fontSize: 20, color: dark),
                      ),
                    ),
                ],
              ),
              if (showSolution) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: MathText(
                      solution,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ),
                ),
              ],
              if (feedback.isNotEmpty) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: math.max(
                      80,
                      MediaQuery.sizeOf(context).height * 0.22,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: MathText(
                      feedback,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                style: AppTheme.chunkyStyle(
                  face: main,
                  edge: dark,
                  foreground: Colors.white,
                  textStyle: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: onContinue,
                child: Text(ok || pending ? 'ادامه' : 'فهمیدم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
