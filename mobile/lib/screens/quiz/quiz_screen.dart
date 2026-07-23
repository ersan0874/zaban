import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/services/user_stats_service.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/shop_bottom_sheet.dart';
import 'package:zaban/widgets/stats_header_bar.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitTitle,
    required this.questions,
  });

  final String unitTitle;
  final List<QuestionModel> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final UserStatsService _statsService = userStatsService;

  int _index = 0;
  int _score = 0;
  bool _finished = false;
  bool _shakeHearts = false;
  bool _unitRewarded = false;
  bool _processingAnswer = false;

  QuestionModel get _current => widget.questions[_index];

  Future<void> _onAnswered(bool correct) async {
    if (_processingAnswer) return;
    _processingAnswer = true;

    if (correct) {
      _score++;
    } else {
      await _handleWrongAnswer();
      if (!mounted) return;
      if (!_statsService.isSuper && _statsService.hearts <= 0) {
        _processingAnswer = false;
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    if (_index >= widget.questions.length - 1) {
      await _finishQuiz();
    } else {
      setState(() {
        _index++;
        _processingAnswer = false;
      });
    }
  }

  Future<void> _handleWrongAnswer() async {
    try {
      final result = await _statsService.decreaseHeart();
      if (!mounted) return;

      // Super: hearts not deducted
      if (result.infiniteHearts || result.heartDeducted == false) {
        return;
      }

      setState(() => _shakeHearts = true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _shakeHearts = false);

      if (_statsService.hearts <= 0 && mounted) {
        await showShopBottomSheet(
          context,
          statsService: _statsService,
          message: 'قلب‌هایت تمام شد! برای ادامه ترمیم کن.',
        );
        if (!mounted) return;
        if (_statsService.hearts <= 0) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('no hearts') ||
          message.contains('heart')) {
        await showShopBottomSheet(
          context,
          statsService: _statsService,
          message: 'قلب‌هایت تمام شد!',
        );
        if (mounted && _statsService.hearts <= 0) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message, style: GoogleFonts.vazirmatn()),
          ),
        );
      }
    }
  }

  Future<void> _finishQuiz() async {
    if (!_unitRewarded) {
      _unitRewarded = true;
      try {
        await _statsService.completeUnit();
      } catch (_) {
        // Reward is best-effort; quiz result still shows.
      }
    }

    if (!mounted) return;
    setState(() {
      _finished = true;
      _processingAnswer = false;
    });
  }

  void _skipUnsupported() {
    if (_index >= widget.questions.length - 1) {
      _finishQuiz();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFC), AppColors.mist, Color(0xFFE5F0F2)],
          ),
        ),
        child: SafeArea(
          child: _finished ? _buildResult() : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final total = widget.questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.inkSoft,
              ),
              Expanded(
                child: Text(
                  widget.unitTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_index + 1}/$total',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealDeep,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatsHeaderBar(
            statsService: _statsService,
            shakeHearts: _shakeHearts,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_index + 1) / total,
              minHeight: 6,
              backgroundColor: AppColors.mistDeep,
              color: AppColors.amber,
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Padding(
              key: ValueKey(_current.id),
              padding: const EdgeInsets.all(24),
              child: QuestionModuleView(
                question: _current,
                onAnswered: _onAnswered,
                onSkip: _skipUnsupported,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final total = widget.questions.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _score == total
                      ? const [AppColors.success, Color(0xFF047857)]
                      : const [AppColors.teal, AppColors.tealDeep],
                ),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'آزمون تمام شد',
              style: GoogleFonts.vazirmatn(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_score از $total پاسخ درست',
              style: GoogleFonts.vazirmatn(
                fontSize: 16,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+۲۰ 💎  |  Streak: ${_statsService.streak} 🔥',
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.tealDeep,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'بازگشت به مسیر',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smart renderer that switches UI by question `type`.
class QuestionModuleView extends StatelessWidget {
  const QuestionModuleView({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.onSkip,
  });

  final QuestionModel question;
  final ValueChanged<bool> onAnswered;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case 'multiple_choice':
        return _MultipleChoiceModule(
          question: question,
          onAnswered: onAnswered,
        );
      case 'matching':
      case 'cloze_typing':
        return _PlaceholderModule(
          type: question.type,
          prompt: question.prompt,
          onSkip: onSkip,
        );
      default:
        return _PlaceholderModule(
          type: question.type,
          prompt: question.prompt,
          onSkip: onSkip,
        );
    }
  }
}

class _MultipleChoiceModule extends StatefulWidget {
  const _MultipleChoiceModule({
    required this.question,
    required this.onAnswered,
  });

  final QuestionModel question;
  final ValueChanged<bool> onAnswered;

  @override
  State<_MultipleChoiceModule> createState() => _MultipleChoiceModuleState();
}

class _MultipleChoiceModuleState extends State<_MultipleChoiceModule> {
  String? _selected;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options;
    final correct = widget.question.correctOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.45,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 28),
        ...options.map((option) {
          final isSelected = _selected == option;
          final isCorrectOption = option == correct;

          Color bg = Colors.white.withValues(alpha: 0.85);
          Color border = AppColors.mistDeep;
          Color text = AppColors.ink;

          if (_checked) {
            if (isCorrectOption) {
              bg = const Color(0xFFD1FAE5);
              border = AppColors.success;
              text = AppColors.success;
            } else if (isSelected && !isCorrectOption) {
              bg = const Color(0xFFFEE2E2);
              border = AppColors.danger;
              text = AppColors.danger;
            }
          } else if (isSelected) {
            bg = AppColors.amberSoft;
            border = AppColors.amber;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _checked
                    ? null
                    : () => setState(() => _selected = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.8),
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        ElevatedButton(
          onPressed: _selected == null || _checked
              ? null
              : () {
                  setState(() => _checked = true);
                  final ok = _selected == correct;
                  widget.onAnswered(ok);
                },
          child: Text(
            'بررسی',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderModule extends StatelessWidget {
  const _PlaceholderModule({
    required this.type,
    required this.prompt,
    required this.onSkip,
  });

  final String type;
  final String prompt;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mistDeep),
          ),
          child: Column(
            children: [
              Icon(Icons.construction_rounded,
                  size: 40, color: AppColors.amber.withValues(alpha: 0.9)),
              const SizedBox(height: 14),
              Text(
                'ماژول تعاملی [$type] در حال ساخت است',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: onSkip,
          child: Text(
            'رد شدن',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
