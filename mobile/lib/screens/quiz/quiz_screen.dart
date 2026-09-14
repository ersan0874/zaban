import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/quiz/modules/exercise_modules.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

/// Quiz fed by a server lesson session; grading happens on submit.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitTitle,
    required this.sessionId,
    required this.questions,
  });

  final String unitTitle;
  final String sessionId;
  final List<QuestionModel> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final _sessions = SessionRepository();
  int _index = 0;
  bool _finished = false;
  bool _submitting = false;
  bool _showAnswerBurst = false;
  String? _error;
  SessionSubmitResult? _result;
  final Map<String, dynamic> _responses = {};
  late final AnimationController _burstController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  QuestionModel get _current => widget.questions[_index];

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  Future<void> _onModuleSubmit(Map<String, dynamic> response) async {
    _responses[_current.id] = response;
    if (_index >= widget.questions.length - 1) {
      await _submitAll();
      return;
    }

    setState(() => _showAnswerBurst = true);
    _burstController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() {
      _index++;
      _showAnswerBurst = false;
    });
  }

  Future<void> _submitAll() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final answers = widget.questions.map((q) {
        return {
          'exerciseId': q.id,
          'response': _responses[q.id] ?? <String, dynamic>{},
        };
      }).toList();
      final result = await _sessions.submit(
        sessionId: widget.sessionId,
        answers: answers,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _finished = true;
        _submitting = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = 'ارسال پاسخ‌ها ناموفق بود';
        _submitting = false;
      });
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
          child: _submitting
              ? const Center(child: CircularProgressIndicator())
              : _finished
                  ? _buildResult()
                  : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final total = widget.questions.length;
    if (total == 0) {
      return Center(
        child: Text(
          'تمرینی در این نشست نیست',
          style: GoogleFonts.vazirmatn(color: AppColors.slate),
        ),
      );
    }

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
        if (_current.isReview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'مرور هوشمند',
              style: GoogleFonts.vazirmatn(
                color: AppColors.amber,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: GoogleFonts.vazirmatn(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Padding(
                  key: ValueKey(_current.id),
                  padding: const EdgeInsets.all(24),
                  child: ExerciseModuleRouter(
                    question: _current,
                    onSubmitResponse: _onModuleSubmit,
                  ),
                ),
              ),
              if (_showAnswerBurst)
                IgnorePointer(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _burstController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal.withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final correct = _result?.correctCount ?? 0;
    final total = _result?.totalCount ?? widget.questions.length;
    final percent = _result?.scorePercent ?? 0;

    final passed = percent >= 70;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: passed
                        ? const [AppColors.success, Color(0xFF047857)]
                        : const [AppColors.amber, Color(0xFFB45309)],
                  ),
                ),
                child: Icon(
                  passed ? Icons.check_rounded : Icons.refresh_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
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
              '$correct از $total پاسخ درست ($percent٪)',
              style: GoogleFonts.vazirmatn(
                fontSize: 16,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نمره توسط سرور محاسبه شد',
              style: GoogleFonts.vazirmatn(
                fontSize: 13,
                color: AppColors.slate,
              ),
            ),
            if ((_result?.comboRewards.isNotEmpty ?? false)) ...[
              const SizedBox(height: 20),
              _ComboBurst(
                totalEnergy: _result!.comboRewards
                    .fold<int>(0, (s, r) => s + r.energyAwarded),
                count: _result!.comboRewards.length,
              ),
            ],
            if (_result?.energyBalance != null) ...[
              const SizedBox(height: 12),
              Text(
                'انرژی باقی‌مانده: ${_result!.energyBalance}',
                style: GoogleFonts.vazirmatn(
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealDeep,
                ),
              ),
            ],
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

class _ComboBurst extends StatefulWidget {
  const _ComboBurst({required this.totalEnergy, required this.count});

  final int totalEnergy;
  final int count;

  @override
  State<_ComboBurst> createState() => _ComboBurstState();
}

class _ComboBurstState extends State<_ComboBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Text(
              'کومبو!',
              style: GoogleFonts.vazirmatn(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.count} پاداش سرور · +${widget.totalEnergy} انرژی',
              style: GoogleFonts.vazirmatn(
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
