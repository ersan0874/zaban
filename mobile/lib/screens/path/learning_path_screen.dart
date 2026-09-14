import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/path_node_model.dart';
import 'package:zaban/repositories/curriculum_repository.dart';
import 'package:zaban/repositories/energy_repository.dart';
import 'package:zaban/repositories/gamification_repository.dart';
import 'package:zaban/repositories/reengagement_repository.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/auth/auth_gate.dart';
import 'package:zaban/screens/auth/profile_screen.dart';
import 'package:zaban/screens/gamification/gamification_screen.dart';
import 'package:zaban/screens/progress/progress_screen.dart';
import 'package:zaban/screens/quiz/quiz_screen.dart';
import 'package:zaban/screens/study/word_study_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final _curriculum = CurriculumRepository();
  final _energyRepo = EnergyRepository();
  final _gamiRepo = GamificationRepository();
  final _reengagement = ReengagementRepository();
  final _sessions = SessionRepository();

  bool _loading = true;
  bool _startingDiagnostic = false;
  String? _error;
  String? _courseTitle;
  List<PathNodeModel> _nodes = const [];
  EnergySnapshot? _energy;
  GamificationSnapshot? _gami;
  ReengagementStatus? _reentry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadPath();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await _curriculum.listCourses();
      EnergySnapshot? energy;
      GamificationSnapshot? gami;
      try {
        energy = await _energyRepo.getEnergy();
      } catch (_) {
        energy = null;
      }
      try {
        gami = await _gamiRepo.getSnapshot();
      } catch (_) {
        gami = null;
      }
      ReengagementStatus? reentry;
      try {
        reentry = await _reengagement.getStatus();
      } catch (_) {
        reentry = null;
      }
      if (courses.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'هنوز دوره‌ای منتشر نشده است';
          _nodes = const [];
          _energy = energy;
          _gami = gami;
          _reentry = reentry;
        });
        return;
      }
      final path = await _curriculum.getPath(courses.first.id);
      if (!mounted) return;
      setState(() {
        _courseTitle = path.course.title;
        _nodes = path.nodes;
        _energy = energy;
        _gami = gami;
        _reentry = reentry;
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
        _error = 'بارگذاری مسیر ناموفق بود';
      });
    }
  }

  Future<void> _startDiagnostic() async {
    final lessonId = _reentry?.diagnosticLessonId;
    if (lessonId == null || lessonId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'درس آزمون بازگشت یافت نشد',
            style: GoogleFonts.vazirmatn(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _startingDiagnostic = true;
      _error = null;
    });

    try {
      final session = await _sessions.startLessonSession(lessonId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizScreen(
            unitTitle: _reentry?.diagnosticLessonTitle ?? 'آزمون بازگشت',
            sessionId: session.sessionId,
            questions: session.exercises,
          ),
        ),
      );
      await _loadPath();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'شروع آزمون بازگشت ناموفق بود');
    } finally {
      if (mounted) setState(() => _startingDiagnostic = false);
    }
  }

  void _onNodeTap(PathNodeModel node) {
    if (node.status == PathNodeStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.inkSoft,
          content: Text(
            'این یونیت هنوز قفل است',
            style: GoogleFonts.vazirmatn(),
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }
    _showUnitSheet(node);
  }

  void _showUnitSheet(PathNodeModel node) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      builder: (context) => _UnitActionSheet(node: node),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FBFC),
              AppColors.mist,
              AppColors.mistDeep,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'پیشرفت بازی',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GamificationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        IconButton(
                          tooltip: 'پیشرفت و مرور',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProgressScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.psychology_alt_rounded,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'زبان',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.1,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'پروفایل',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileScreen(
                                  onLoggedOut: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AuthGate(),
                                      ),
                                      (_) => false,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.person_rounded,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    // refresh stays below title row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'تلاش دوباره',
                        onPressed: _loading ? null : _loadPath,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _courseTitle ?? 'مسیر یادگیری',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_energy != null) ...[
                      const SizedBox(height: 10),
                      _EnergyChip(energy: _energy!),
                    ],
                    if (_gami != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'استریک ${_gami!.streakCount}  ·  قلب ${_gami!.hearts}/${_gami!.heartsCap}  ·  XP ${_gami!.xp}'
                        '${_gami!.unopenedLootCount > 0 ? '  ·  جعبه ${_gami!.unopenedLootCount}' : ''}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_reentry?.requiresDiagnostic == true) ...[
                      const SizedBox(height: 12),
                      _DiagnosticBanner(
                        title: _reentry!.diagnosticLessonTitle ?? 'آزمون بازگشت',
                        busy: _startingDiagnostic,
                        onStart: _startDiagnostic,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(child: _buildBody(nodes)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<PathNodeModel> nodes) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPath,
                child: Text(
                  'تلاش دوباره',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (nodes.isEmpty) {
      return Center(
        child: Text(
          'مسیری برای نمایش نیست',
          style: GoogleFonts.vazirmatn(color: AppColors.slate),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const rowHeight = 140.0;
        final totalHeight = nodes.length * rowHeight + 80;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            height: totalHeight,
            width: constraints.maxWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ZigzagPathPainter(
                      nodeCount: nodes.length,
                      rowHeight: rowHeight,
                    ),
                  ),
                ),
                ...List.generate(nodes.length, (index) {
                  final node = nodes[index];
                  final isLeft = index.isEven;
                  final top = index * rowHeight;
                  final horizontalPadding = constraints.maxWidth * 0.14;

                  return Positioned(
                    top: top,
                    left: isLeft ? horizontalPadding : null,
                    right: isLeft ? null : horizontalPadding,
                    child: _PathNode(
                      node: node,
                      pulse: node.status == PathNodeStatus.active
                          ? _pulseController
                          : null,
                      onTap: () => _onNodeTap(node),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiagnosticBanner extends StatelessWidget {
  const _DiagnosticBanner({
    required this.title,
    required this.onStart,
    required this.busy,
  });

  final String title;
  final VoidCallback onStart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            'چند روز نبودی — اول $title را انجام بده',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onStart,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.fact_check_rounded),
              label: Text(
                'شروع آزمون بازگشت',
                style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  const _EnergyChip({required this.energy});

  final EnergySnapshot energy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mistDeep),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            '${energy.balance} / ${energy.cap}',
            style: GoogleFonts.vazirmatn(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'هر ${energy.regenIntervalMinutes} دقیقه +۱',
            style: GoogleFonts.vazirmatn(
              fontSize: 11,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.node,
    required this.onTap,
    this.pulse,
  });

  final PathNodeModel node;
  final VoidCallback onTap;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final locked = node.status == PathNodeStatus.locked;
    final active = node.status == PathNodeStatus.active;
    final completed = node.status == PathNodeStatus.completed;

    Widget nodeBody = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: locked
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: completed
                    ? const [AppColors.success, Color(0xFF047857)]
                    : const [AppColors.teal, AppColors.tealDeep],
              ),
        color: locked ? const Color(0xFFE2E8F0) : null,
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: (active ? AppColors.teal : AppColors.success)
                      .withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
        border: Border.all(
          color: locked ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.55),
          width: 2.5,
        ),
      ),
      child: Icon(
        locked
            ? Icons.lock_rounded
            : completed
                ? Icons.check_rounded
                : Icons.auto_stories_rounded,
        color: locked ? AppColors.locked : Colors.white,
        size: 30,
      ),
    );

    if (pulse != null) {
      nodeBody = AnimatedBuilder(
        animation: pulse!,
        builder: (context, child) {
          final scale = 1 + (pulse!.value * 0.06);
          return Transform.scale(scale: scale, child: child);
        },
        child: nodeBody,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          nodeBody,
          const SizedBox(height: 10),
          SizedBox(
            width: 120,
            child: Text(
              'یونیت ${node.order}',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: locked ? AppColors.locked : AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZigzagPathPainter extends CustomPainter {
  _ZigzagPathPainter({
    required this.nodeCount,
    required this.rowHeight,
  });

  final int nodeCount;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount < 2) return;

    final paint = Paint()
      ..color = AppColors.pathLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < nodeCount; i++) {
      final isLeft = i.isEven;
      final x = isLeft ? size.width * 0.22 : size.width * 0.78;
      final y = i * rowHeight + 39;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevLeft = (i - 1).isEven;
        final prevX = prevLeft ? size.width * 0.22 : size.width * 0.78;
        final prevY = (i - 1) * rowHeight + 39;
        final midY = (prevY + y) / 2;
        path.cubicTo(
          prevX,
          midY,
          x,
          midY,
          x,
          y,
        );
      }
    }

    _drawDashedPath(canvas, path, dashPaint);
    canvas.drawPath(path, paint..color = AppColors.pathLine.withValues(alpha: 0.55));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 10.0;
      const gap = 8.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ZigzagPathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount ||
        oldDelegate.rowHeight != rowHeight;
  }
}

class _UnitActionSheet extends StatefulWidget {
  const _UnitActionSheet({required this.node});

  final PathNodeModel node;

  @override
  State<_UnitActionSheet> createState() => _UnitActionSheetState();
}

class _UnitActionSheetState extends State<_UnitActionSheet> {
  final _curriculum = CurriculumRepository();
  final _sessions = SessionRepository();
  bool _busy = false;
  String? _error;

  Future<void> _startStudy() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final unit = await _curriculum.getUnit(widget.node.id);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WordStudyScreen(
            unitTitle: unit.title,
            words: unit.words,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'بارگذاری مطالعه ناموفق بود';
      });
    }
  }

  Future<void> _startQuiz() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final unit = await _curriculum.getUnit(widget.node.id);
      final lesson = unit.quizLesson;
      if (lesson == null) {
        setState(() {
          _busy = false;
          _error = 'درسی برای آزمون یافت نشد';
        });
        return;
      }
      final session = await _sessions.startLessonSession(lesson.id);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizScreen(
            unitTitle: unit.title,
            sessionId: session.sessionId,
            questions: session.exercises,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'شروع آزمون ناموفق بود';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mistDeep,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.tealDeep],
              ),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            node.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.subtitle,
            style: GoogleFonts.vazirmatn(
              fontSize: 13,
              color: AppColors.slate,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _startStudy,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chrome_reader_mode_rounded),
              label: const Text('شروع مطالعه'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _startQuiz,
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('شروع آزمون'),
            ),
          ),
        ],
      ),
    );
  }
}
