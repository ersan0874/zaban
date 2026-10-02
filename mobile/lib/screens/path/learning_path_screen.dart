import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/path_node_model.dart';
import 'package:zaban/repositories/curriculum_repository.dart';
import 'package:zaban/repositories/economy_repository.dart';
import 'package:zaban/repositories/energy_repository.dart';
import 'package:zaban/repositories/gamification_repository.dart';
import 'package:zaban/repositories/reengagement_repository.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/auth/auth_gate.dart';
import 'package:zaban/screens/auth/profile_screen.dart';
import 'package:zaban/screens/progress/progress_screen.dart';
import 'package:zaban/screens/quiz/quiz_screen.dart';
import 'package:zaban/screens/study/word_study_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key, this.embedded = false});

  /// When true, hides redundant nav icons (used inside HomeShell).
  final bool embedded;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final _curriculum = CurriculumRepository();
  final _energyRepo = EnergyRepository();
  final _economyRepo = EconomyRepository();
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
  int _gems = 0;
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
      var gems = 0;
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
      try {
        gems = (await _economyRepo.getWallet()).gems;
      } catch (_) {
        gems = 0;
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
          _gems = gems;
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
        _gems = gems;
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
            energy: session.energy,
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
      builder: (context) => _UnitActionSheet(
        node: node,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _nodes;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatsStrip(
                      energy: _energy,
                      gami: _gami,
                      gems: _gems,
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
                      Icons.insights_rounded,
                      color: AppColors.sky,
                    ),
                  ),
                  IconButton(
                    tooltip: 'تازه‌سازی',
                    onPressed: _loading ? null : _loadPath,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.locked,
                    ),
                  ),
                  if (!widget.embedded)
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
                        color: AppColors.grape,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  _UnitBanner(
                    courseTitle: _courseTitle ?? 'مسیر یادگیری',
                    nodes: nodes,
                  ),
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
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppColors.locked,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadPath,
                child: const Text('تلاش دوباره'),
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

    // Nodes sway gently left and right like a winding trail.
    const swing = [0.0, -0.45, -0.75, -0.45, 0.0, 0.45, 0.75, 0.45];
    const rowHeight = 104.0;
    const bubbleSpace = 44.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final amplitude = math.min(constraints.maxWidth * 0.22, 110.0);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            final active = node.status == PathNodeStatus.active;
            final dx = swing[index % swing.length] * amplitude;
            return SizedBox(
              height: rowHeight + (active ? bubbleSpace : 0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: _PathNode(
                    node: node,
                    pulse: active ? _pulseController : null,
                    onTap: () => _onNodeTap(node),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.courseTitle, required this.nodes});

  final String courseTitle;
  final List<PathNodeModel> nodes;

  @override
  Widget build(BuildContext context) {
    final done =
        nodes.where((n) => n.status == PathNodeStatus.completed).length;
    final current = nodes.cast<PathNodeModel?>().firstWhere(
          (n) => n!.status == PathNodeStatus.active,
          orElse: () => null,
        );
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.leafDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.leaf,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nodes.isEmpty
                        ? 'مسیر یادگیری'
                        : 'یونیت ${current?.order ?? done} از ${nodes.length}',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    current?.title ?? courseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.energy,
    required this.gami,
    required this.gems,
  });

  final EnergySnapshot? energy;
  final GamificationSnapshot? gami;
  final int gems;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatChip(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.flame,
            label: '${gami?.streakCount ?? 0}',
          ),
          _StatChip(
            icon: Icons.diamond_rounded,
            color: AppColors.grape,
            label: '$gems',
          ),
          _StatChip(
            icon: Icons.favorite_rounded,
            color: AppColors.coral,
            label: gami == null ? '—' : '${gami!.hearts}',
          ),
          _StatChip(
            icon: Icons.bolt_rounded,
            color: AppColors.sky,
            label: energy == null ? '—' : '${energy!.balance}',
          ),
          if ((gami?.unopenedLootCount ?? 0) > 0)
            _StatChip(
              icon: Icons.card_giftcard_rounded,
              color: AppColors.leaf,
              label: '${gami!.unopenedLootCount}',
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 3),
          Text(label, style: AppTheme.latin(fontSize: 16, color: color)),
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

    final face = locked
        ? AppColors.line
        : completed
            ? AppColors.sun
            : AppColors.leaf;
    final edge = locked
        ? AppColors.lineDark
        : completed
            ? AppColors.sunDark
            : AppColors.leafDark;

    Widget coin = Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(color: edge, shape: BoxShape.circle),
      child: Container(
        decoration: BoxDecoration(color: face, shape: BoxShape.circle),
        child: Icon(
          locked
              ? Icons.lock_rounded
              : completed
                  ? Icons.check_rounded
                  : Icons.star_rounded,
          color: locked ? AppColors.locked : Colors.white,
          size: 34,
        ),
      ),
    );

    if (active) {
      coin = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.leafSoft, width: 8),
            ),
          ),
          coin,
          Positioned(
            top: -44,
            child: _StartBubble(pulse: pulse),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: '${node.title} — یونیت ${node.order}',
      child: GestureDetector(
        onTap: onTap,
        child: coin,
      ),
    );
  }
}

class _StartBubble extends StatelessWidget {
  const _StartBubble({this.pulse});

  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line, width: 2),
      ),
      child: Text(
        'شروع',
        style: GoogleFonts.vazirmatn(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.leaf,
        ),
      ),
    );
    if (pulse == null) return bubble;
    return AnimatedBuilder(
      animation: pulse!,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * pulse!.value),
        child: child,
      ),
      child: bubble,
    );
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

  /// Set when the unit has several lessons and the learner must pick one.
  UnitDetail? _unit;

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
      if (unit.practiceLessons.length > 1) {
        setState(() {
          _busy = false;
          _unit = unit;
        });
        return;
      }
      final lesson = unit.quizLesson;
      if (lesson == null) {
        setState(() {
          _busy = false;
          _error = 'درسی برای آزمون یافت نشد';
        });
        return;
      }
      await _startLesson(unit, lesson);
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

  Future<void> _pickLesson(UnitDetail unit, UnitLessonSummary lesson) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _startLesson(unit, lesson);
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

  Future<void> _startLesson(UnitDetail unit, UnitLessonSummary lesson) async {
    final session = await _sessions.startLessonSession(lesson.id);
    if (!mounted) return;
    Navigator.pop(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          unitTitle:
              unit.practiceLessons.length > 1 ? lesson.title : unit.title,
          sessionId: session.sessionId,
          questions: session.exercises,
          notes: session.notes,
          energy: session.energy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final onLeaf = AppTheme.chunkyStyle(
      face: Colors.white,
      edge: AppColors.isDark ? AppColors.leafDark : const Color(0xFFD6EFC6),
      foreground: AppColors.leafDark,
      textStyle: GoogleFonts.vazirmatn(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: AppColors.leafDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.leaf,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                node.title,
                style: GoogleFonts.vazirmatn(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'یونیت ${node.order} · ${node.subtitle}',
                style: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (_unit != null) ...[
                Text(
                  'کدام درس را تمرین کنیم؟',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _unit!.practiceLessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final lesson = _unit!.practiceLessons[i];
                      return ElevatedButton(
                        style: onLeaf,
                        onPressed:
                            _busy ? null : () => _pickLesson(_unit!, lesson),
                        child: Text(
                          '${i + 1}. ${lesson.title}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                ElevatedButton(
                  style: onLeaf,
                  onPressed: _busy ? null : _startQuiz,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.leaf,
                          ),
                        )
                      : const Text('شروع آزمون'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: AppTheme.chunkyStyle(
                  face: Colors.transparent,
                  edge: Colors.transparent,
                  foreground: Colors.white,
                  border: Colors.white.withValues(alpha: 0.6),
                  textStyle: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: _busy ? null : _startStudy,
                child: const Text('اول مطالعه کن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
