import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/repositories/energy_repository.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/quiz/answer_feedback_bar.dart';
import 'package:zaban/screens/quiz/combo_screen.dart';
import 'package:zaban/screens/quiz/modules/exercise_modules.dart';
import 'package:zaban/screens/quiz/out_of_energy_sheet.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/services/feedback_fx.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/confetti.dart';
import 'package:zaban/widgets/mascot.dart';
import 'package:zaban/widgets/math_text.dart';

/// Lesson player. Every page (the notes page and each question) is passed
/// through the server, which grades it at once, burns one energy and
/// advances the combo; the final submit only wraps the lesson up.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.unitTitle,
    required this.sessionId,
    required this.questions,
    this.notes = const [],
    this.energy,
  });

  final String unitTitle;
  final String sessionId;
  final List<QuestionModel> questions;

  /// Lesson notes shown before the first exercise (empty = straight to quiz).
  final List<String> notes;

  /// Energy when the session started, for the header counter.
  final EnergySnapshot? energy;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _sessions = SessionRepository();
  int _index = 0;
  bool _finished = false;
  bool _submitting = false;
  bool _checking = false;
  late bool _showingNotes = widget.notes.isNotEmpty;
  String? _error;
  SessionSubmitResult? _result;
  StepResult? _feedback;
  late EnergySnapshot? _energy = widget.energy;
  late int _streak = widget.energy?.comboStreak ?? 0;
  final Map<String, dynamic> _responses = {};

  QuestionModel get _current => widget.questions[_index];

  int get _totalPages =>
      widget.questions.length + (widget.notes.isNotEmpty ? 1 : 0);

  int get _pagesDone =>
      (widget.notes.isNotEmpty && !_showingNotes ? 1 : 0) +
      _index +
      (_feedback != null ? 1 : 0);

  Future<StepResult?> _passPage({
    String? exerciseId,
    Map<String, dynamic>? response,
    String? page,
  }) async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final r = await _sessions.step(
        sessionId: widget.sessionId,
        exerciseId: exerciseId,
        response: response,
        page: page,
      );
      if (!mounted) return null;
      setState(() {
        _energy = r.energy ?? _energy;
        _streak = r.comboStreak;
      });
      return r;
    } on OutOfEnergyException catch (e) {
      if (!mounted) return null;
      setState(() => _energy = e.energy ?? _energy);
      final refilled = await OutOfEnergySheet.show(context, e.energy);
      if (!mounted) return null;
      if (!refilled) {
        Navigator.pop(context);
        return null;
      }
      return _passPage(exerciseId: exerciseId, response: response, page: page);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return null;
    } catch (_) {
      if (mounted) setState(() => _error = 'ارسال پاسخ ناموفق بود؛ دوباره بزن');
      return null;
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _onModuleSubmit(Map<String, dynamic> response) async {
    if (_checking || _feedback != null) return;
    final r = await _passPage(exerciseId: _current.id, response: response);
    if (r == null || !mounted) return;
    _responses[_current.id] = response;
    FeedbackFx.instance.play(r.isCorrect || !r.graded ? Fx.correct : Fx.wrong);
    setState(() => _feedback = r);
  }

  Future<void> _finishNotes() async {
    if (_checking) return;
    final r = await _passPage(page: 'note:0');
    if (r == null || !mounted) return;
    FeedbackFx.instance.play(Fx.tap);
    await _afterPage(r);
  }

  Future<void> _onContinue() async {
    final r = _feedback;
    if (r == null) return;
    await _afterPage(r);
  }

  /// Shared tail of every page: combo reward, energy check, next page.
  Future<void> _afterPage(StepResult r) async {
    if (r.comboReward != null) {
      await ComboScreen.show(context, r.comboReward!);
      if (!mounted) return;
    }
    final lastPage = !_showingNotes && _index >= widget.questions.length - 1;
    if (lastPage || widget.questions.isEmpty) {
      setState(() => _feedback = null);
      await _submitAll();
      return;
    }
    final energy = _energy;
    if (energy != null && energy.isEmpty) {
      final refilled = await OutOfEnergySheet.show(context, energy);
      if (!mounted) return;
      if (!refilled) {
        Navigator.pop(context);
        return;
      }
    }
    setState(() {
      _feedback = null;
      if (_showingNotes) {
        _showingNotes = false;
      } else {
        _index++;
      }
    });
  }

  Future<void> _submitAll() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final answers = widget.questions
          .where((q) => _responses.containsKey(q.id))
          .map((q) => {'exerciseId': q.id, 'response': _responses[q.id]})
          .toList();
      final result = await _sessions.submit(
        sessionId: widget.sessionId,
        answers: answers,
      );
      if (!mounted) return;
      FeedbackFx.instance.play(Fx.complete);
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

  Future<void> _confirmQuit() async {
    if (_pagesDone == 0) {
      Navigator.pop(context);
      return;
    }
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'از درس خارج می‌شوی؟',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'انرژی صفحه‌هایی که رد کردی برنمی‌گردد و این درس تمام‌شده حساب نمی‌شود.',
          style: GoogleFonts.vazirmatn(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'خروج',
              style: GoogleFonts.vazirmatn(color: AppColors.coralDark),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ادامه می‌دهم'),
          ),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: AppColors.snow,
        body: SafeArea(
          bottom: false,
          child: _submitting
              ? const Center(child: CircularProgressIndicator())
              : _finished
                  ? _buildResult()
                  : Column(
                      children: [
                        _buildHeader(),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Text(
                              _error!,
                              style: GoogleFonts.vazirmatn(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Expanded(
                          child: _showingNotes ? _buildNotes() : _buildQuiz(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _totalPages == 0 ? 1 : _totalPages;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'خروج',
            onPressed: _confirmQuit,
            icon: const Icon(Icons.close_rounded, size: 28),
            color: AppColors.locked,
          ),
          const SizedBox(width: 2),
          Expanded(child: _ChunkyProgressBar(value: _pagesDone / total)),
          const SizedBox(width: 10),
          _ComboMeter(streak: _streak),
          const SizedBox(width: 8),
          _EnergyCounter(energy: _energy),
          if (widget.notes.isNotEmpty && !_showingNotes)
            IconButton(
              tooltip: 'نکته‌های درس',
              onPressed: _openNotesSheet,
              icon: const Icon(Icons.lightbulb_rounded),
              color: AppColors.sunDark,
            ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    if (widget.questions.isEmpty) {
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
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
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
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: _checking || _feedback != null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Padding(
                      key: ValueKey(_current.id),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: ExerciseModuleRouter(
                        question: _current,
                        onSubmitResponse: _onModuleSubmit,
                      ),
                    ),
                  ),
                ),
              ),
              if (_checking)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (_feedback != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnswerFeedbackBar(
                    key: ValueKey('fb-${_current.id}'),
                    result: _feedback!,
                    seed: _index,
                    onContinue: _onContinue,
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.unitTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.vazirmatn(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
            ),
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
            onPressed: _checking ? null : _finishNotes,
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
    final result = _result;
    final correct = result?.correctCount ?? 0;
    final total = result?.totalCount ?? widget.questions.length;
    final percent = result?.scorePercent ?? 0;
    final passed = percent >= 70;
    final comboEnergy = (result?.comboRewards ?? const <ComboReward>[])
        .fold<int>(0, (s, r) => s + r.energyAwarded);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Mascot(
                        mood: passed ? MascotMood.cheer : MascotMood.happy,
                        size: 150,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        passed ? 'درس تمام شد!' : 'خوب تمرین کردی!',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: passed ? AppColors.sunDark : AppColors.flame,
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
                      if (result != null && result.streakAfter > 0) ...[
                        const SizedBox(height: 20),
                        _StreakFlame(
                          days: result.streakAfter,
                          grew: result.streakGrew,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ResultTile(
                              label: 'امتیاز',
                              value: '+${result?.xpGained ?? 0}',
                              icon: Icons.star_rounded,
                              color: AppColors.sun,
                              dark: AppColors.sunDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ResultTile(
                              label: 'دقت',
                              value: '$percent%',
                              icon: Icons.track_changes_rounded,
                              color: AppColors.leaf,
                              dark: AppColors.leafDark,
                            ),
                          ),
                          if (result?.energyBalance != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ResultTile(
                                label: 'انرژی',
                                value: '${result!.energyBalance}',
                                icon: Icons.bolt_rounded,
                                color: AppColors.sky,
                                dark: AppColors.skyDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (comboEnergy > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.sunSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.sun, width: 2),
                          ),
                          child: Text(
                            'کومبوها در این درس $comboEnergy انرژی برگرداندند',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w800,
                              color: AppColors.sunDark,
                            ),
                          ),
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
        ),
        if (passed) const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

/// Header chip: current energy (∞ for unlimited subscribers).
class _EnergyCounter extends StatelessWidget {
  const _EnergyCounter({required this.energy});

  final EnergySnapshot? energy;

  @override
  Widget build(BuildContext context) {
    final e = energy;
    if (e == null) return const SizedBox.shrink();
    final low = !e.unlimited && e.balance <= 3;
    final color = low ? AppColors.coral : AppColors.sky;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, color: color, size: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(end: e.balance.toDouble()),
          duration: const Duration(milliseconds: 400),
          builder: (context, v, _) => Text(
            e.unlimited ? '∞' : '${v.round()}',
            style: AppTheme.latin(fontSize: 16, color: color),
          ),
        ),
      ],
    );
  }
}

/// Header chip: pages in a row without a mistake; glows from 2 upward.
class _ComboMeter extends StatelessWidget {
  const _ComboMeter({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= 2;
    return AnimatedScale(
      scale: hot ? 1 : 0.9,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: hot ? AppColors.flame : AppColors.line,
            size: 24,
          ),
          Text(
            '$streak',
            style: AppTheme.latin(
              fontSize: 16,
              color: hot ? AppColors.flame : AppColors.locked,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result-screen streak card; the flame pops when today extended it.
class _StreakFlame extends StatelessWidget {
  const _StreakFlame({required this.days, required this.grew});

  final int days;
  final bool grew;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: grew ? 0.3 : 1, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.flameSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.flame, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.flame,
              size: 40,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استریک $days روزه',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.flameDark,
                  ),
                ),
                Text(
                  grew ? 'امروز هم شعله را روشن نگه داشتی!' : 'فردا هم بیا!',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
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
