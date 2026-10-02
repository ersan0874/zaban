import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/quiz/modules/exercise_modules.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/math_text.dart';

/// Quiz fed by a server lesson session; grading happens on submit.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitTitle,
    required this.sessionId,
    required this.questions,
    this.notes = const [],
  });

  final String unitTitle;
  final String sessionId;
  final List<QuestionModel> questions;

  /// Lesson notes shown before the first exercise (empty = straight to quiz).
  final List<String> notes;

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
  late bool _showingNotes = widget.notes.isNotEmpty;
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
      backgroundColor: AppColors.snow,
      body: SafeArea(
        child: _submitting
            ? const Center(child: CircularProgressIndicator())
            : _finished
                ? _buildResult()
                : _showingNotes
                    ? _buildNotes()
                    : _buildQuiz(),
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
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'خروج',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 28),
                color: AppColors.locked,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ChunkyProgressBar(value: (_index + 1) / total),
              ),
              const SizedBox(width: 12),
              Text(
                '${_index + 1}/$total',
                style: AppTheme.latin(fontSize: 15, color: AppColors.slate),
              ),
              if (widget.notes.isNotEmpty)
                IconButton(
                  tooltip: 'نکته‌های درس',
                  onPressed: _openNotesSheet,
                  icon: const Icon(Icons.lightbulb_rounded),
                  color: AppColors.sunDark,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            children: [
              if (_current.isReview) ...[
                const Icon(
                  Icons.replay_circle_filled_rounded,
                  color: AppColors.grape,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'مرور هوشمند',
                  style: GoogleFonts.vazirmatn(
                    color: AppColors.grape,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.unitTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
            ],
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
                        color: AppColors.leaf,
                        border: Border.all(color: AppColors.leafSoft, width: 6),
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

  Widget _buildNotes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'خروج',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 28),
                color: AppColors.locked,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.unitTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.sun,
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                'نکته‌های این درس',
                style: GoogleFonts.vazirmatn(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'اول این نکته‌ها را بخوان، بعد تمرین کن.',
            style: GoogleFonts.vazirmatn(fontSize: 13, color: AppColors.slate),
          ),
          const SizedBox(height: 16),
          Expanded(child: _NotesList(notes: widget.notes)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => setState(() => _showingNotes = false),
            child: const Text('شروع تمرین'),
          ),
        ],
      ),
    );
  }

  void _openNotesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'نکته‌های این درس',
                style: GoogleFonts.vazirmatn(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _NotesList(notes: widget.notes)),
            ],
          ),
        ),
      ),
    );
  }

  /// Per-question explanations, essay scores and AI feedback.
  List<Widget> _buildFeedback() {
    final byId = {for (final q in widget.questions) q.id: q};
    final items = (_result?.results ?? const <Map<String, dynamic>>[])
        .where(
          (r) =>
              (r['feedback'] is String &&
                  (r['feedback'] as String).trim().isNotEmpty) ||
              (r['gradingStatus'] != null && r['gradingStatus'] != 'graded'),
        )
        .toList();
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 28),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'بازخورد پاسخ‌ها',
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...items.map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FeedbackCard(
            result: r,
            question: byId[r['exerciseId']],
          ),
        ),
      ),
    ];
  }

  Widget _buildResult() {
    final correct = _result?.correctCount ?? 0;
    final total = _result?.totalCount ?? widget.questions.length;
    final percent = _result?.scorePercent ?? 0;

    final passed = percent >= 70;
    final accent = passed ? AppColors.sunDark : AppColors.flame;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: passed ? AppColors.sunSoft : AppColors.leafSoft,
                      ),
                      child: Icon(
                        passed
                            ? Icons.emoji_events_rounded
                            : Icons.fitness_center_rounded,
                        color: passed ? AppColors.sun : AppColors.leaf,
                        size: 92,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    passed ? 'درس تمام شد!' : 'خوب تمرین کردی!',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    passed
                        ? '$correct از $total پاسخ درست بود'
                        : '$correct از $total درست؛ یک بار دیگر امتحان کن',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultTile(
                          label: 'پاسخ درست',
                          value: '$correct/$total',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.leaf,
                          dark: AppColors.leafDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResultTile(
                          label: 'دقت',
                          value: '$percent%',
                          icon: Icons.track_changes_rounded,
                          color: AppColors.sun,
                          dark: AppColors.sunDark,
                        ),
                      ),
                      if (_result?.energyBalance != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResultTile(
                            label: 'انرژی',
                            value: '${_result!.energyBalance}',
                            icon: Icons.bolt_rounded,
                            color: AppColors.sky,
                            dark: AppColors.skyDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if ((_result?.comboRewards.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 16),
                    _ComboBurst(
                      totalEnergy: _result!.comboRewards
                          .fold<int>(0, (s, r) => s + r.energyAwarded),
                      count: _result!.comboRewards.length,
                    ),
                  ],
                  ..._buildFeedback(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ادامه'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes});
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.sunSoft,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.sun, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.sun,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${i + 1}',
                style: AppTheme.latin(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MathText(
                notes[i],
                style: GoogleFonts.vazirmatn(
                  fontSize: 15,
                  height: 1.7,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.result, required this.question});

  final Map<String, dynamic> result;
  final QuestionModel? question;

  @override
  Widget build(BuildContext context) {
    final status = result['gradingStatus']?.toString() ?? 'graded';
    final correct = result['isCorrect'] == true;
    final score = result['score'];
    final feedback = result['feedback']?.toString().trim() ?? '';
    final type = result['type']?.toString() ?? question?.type ?? '';

    final (IconData icon, Color color, Color soft, String label) =
        switch (status) {
      'pending' => (
          Icons.hourglass_top_rounded,
          AppColors.sky,
          AppColors.skySoft,
          'در صف تصحیح هوش مصنوعی؛ بعداً نمره‌اش ثبت می‌شود',
        ),
      'ungraded' => (
          Icons.menu_book_rounded,
          AppColors.grape,
          AppColors.mist,
          'تصحیح خودکار امروز در دسترس نیست؛ پاسخ نمونه را ببین',
        ),
      _ => correct
          ? (
              Icons.check_circle_rounded,
              AppColors.leaf,
              AppColors.leafSoft,
              'درست',
            )
          : (
              Icons.cancel_rounded,
              AppColors.coral,
              AppColors.coralSoft,
              'نادرست',
            ),
    };

    final content = question?.content ?? const <String, dynamic>{};
    final title = (content['question'] ?? content['statement'])?.toString() ??
        question?.prompt ??
        '';
    final showScore = status == 'graded' && type == 'essay' && score is num;

    return Container(
      width: double.infinity,
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
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (showScore)
                Text(
                  '${(score * 100).round()}%',
                  style: AppTheme.latin(fontSize: 18, color: color),
                ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(
              title,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(
              feedback,
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

class _ChunkyProgressBar extends StatelessWidget {
  const _ChunkyProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(99),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.leaf,
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.dark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: GoogleFonts.vazirmatn(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    style: AppTheme.latin(fontSize: 18, color: dark),
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
          color: AppColors.sunSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sun, width: 2),
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
              '${widget.count} پاداش · +${widget.totalEnergy} انرژی',
              style: GoogleFonts.vazirmatn(
                fontWeight: FontWeight.w800,
                color: AppColors.sunDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
