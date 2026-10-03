import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/path_item_model.dart';
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
import 'package:zaban/widgets/late_grades_sheet.dart';

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
  String? _courseId;
  List<PathItemModel> _items = const [];

  /// The stop the learner is on; the path scrolls to it after loading.
  final _currentKey = GlobalKey();
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
    // Essay answers that the AI graded after the learner left the lesson.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLateGradesIfAny(context);
    });
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
          _items = const [];
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
        _courseId = path.course.id;
        _items = path.items;
        _energy = energy;
        _gami = gami;
        _gems = gems;
        _reentry = reentry;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _currentKey.currentContext;
        if (target != null && mounted) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.35,
            duration: const Duration(milliseconds: 350),
          );
        }
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

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inkSoft,
        content: Text(
          text,
          style: GoogleFonts.vazirmatn(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _onItemTap(PathItemModel item) {
    if (item.kind == PathItemKind.chest) {
      if (item.isCompleted) {
        _toast('این جعبه را قبلاً باز کرده‌ای');
      } else if (item.isLocked) {
        _toast('درس‌های قبل از این جعبه را تمام کن تا باز شود');
      } else {
        _openChest(item);
      }
      return;
    }
    if (item.isLocked) {
      _toast(
        item.kind == PathItemKind.exam
            ? 'این آزمون بعد از تمام شدن درس‌های قبلش باز می‌شود'
            : 'این درس هنوز قفل است؛ اول مرحله‌های قبلی را تمام کن',
      );
      return;
    }
    final courseId = _courseId;
    if (courseId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      builder: (context) => _ItemSheet(
        item: item,
        courseId: courseId,
        // Energy, hearts and progress change inside a lesson; refresh the
        // header and path once the learner comes back, however they left.
        onLessonClosed: () {
          if (mounted) _loadPath();
        },
      ),
    );
  }

  Future<void> _openChest(PathItemModel item) async {
    final courseId = _courseId;
    if (courseId == null) return;
    try {
      final rewards = await _curriculum.openChest(courseId, item.position);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _ChestDialog(rewards: rewards),
      );
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('باز کردن جعبه ناموفق بود');
    }
    if (mounted) await _loadPath();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

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
                    items: items,
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
            Expanded(child: _buildBody(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<PathItemModel> items) {
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
    if (items.isEmpty) {
      return Center(
        child: Text(
          'مسیری برای نمایش نیست',
          style: GoogleFonts.vazirmatn(color: AppColors.slate),
        ),
      );
    }

    // A small heading wherever a new unit starts, then its stops.
    final rows = <Object>[];
    String? unitId;
    for (final item in items) {
      if (item.unitId != unitId) {
        unitId = item.unitId;
        rows.add(item.unitTitle);
      }
      rows.add(item);
    }

    // Stops sway gently left and right like a winding trail.
    const swing = [0.0, -0.45, -0.75, -0.45, 0.0, 0.45, 0.75, 0.45];

    return LayoutBuilder(
      builder: (context, constraints) {
        final amplitude = math.min(constraints.maxWidth * 0.2, 100.0);
        var stop = 0;
        final offsets = [
          for (final row in rows)
            row is PathItemModel ? swing[stop++ % swing.length] : 0.0,
        ];
        final current = items.cast<PathItemModel?>().firstWhere(
              (i) => i!.isActive && i.kind != PathItemKind.chest,
              orElse: () => null,
            );
        // Built all at once (a course has a few dozen stops) so the path
        // can scroll to the current one.
        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            for (var index = 0; index < rows.length; index++)
              if (rows[index] case final String title)
                _UnitHeading(title: title)
              else if (rows[index] case final PathItemModel item)
                Padding(
                  key: identical(item, current) ? _currentKey : null,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Transform.translate(
                    offset: Offset(offsets[index] * amplitude, 0),
                    child: _PathStop(
                      item: item,
                      pulse: item.isActive ? _pulseController : null,
                      onTap: () => _onItemTap(item),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.courseTitle, required this.items});

  final String courseTitle;
  final List<PathItemModel> items;

  @override
  Widget build(BuildContext context) {
    final lessons = items.where((i) => i.kind == PathItemKind.lesson).toList();
    final done = lessons.where((i) => i.isCompleted).length;
    final current = items.cast<PathItemModel?>().firstWhere(
          (i) => i!.isActive && i.kind != PathItemKind.chest,
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
                    lessons.isEmpty
                        ? 'مسیر یادگیری'
                        : '$done از ${lessons.length} درس تمام شده',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    current?.unitTitle ?? courseTitle,
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

class _UnitHeading extends StatelessWidget {
  const _UnitHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.line, thickness: 2)),
          const SizedBox(width: 10),
          Flexible(
            flex: 3,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.vazirmatn(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.slate,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.line, thickness: 2)),
        ],
      ),
    );
  }
}

/// A stop on the path: a round coin with its name underneath.
class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.item,
    required this.onTap,
    this.pulse,
  });

  final PathItemModel item;
  final VoidCallback onTap;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final locked = item.isLocked;
    final completed = item.isCompleted;

    final (Color face, Color edge, IconData icon) = switch (item.kind) {
      _ when locked => (
          AppColors.line,
          AppColors.lineDark,
          item.kind == PathItemKind.chest
              ? Icons.card_giftcard_rounded
              : Icons.lock_rounded,
        ),
      PathItemKind.lesson => completed
          ? (AppColors.sun, AppColors.sunDark, Icons.check_rounded)
          : (AppColors.leaf, AppColors.leafDark, Icons.star_rounded),
      PathItemKind.exam => completed
          ? (AppColors.sun, AppColors.sunDark, Icons.emoji_events_rounded)
          : (AppColors.grape, AppColors.grapeDark, Icons.emoji_events_rounded),
      PathItemKind.chest => completed
          ? (AppColors.line, AppColors.lineDark, Icons.check_rounded)
          : (AppColors.flame, AppColors.flameDark, Icons.card_giftcard_rounded),
    };
    final size = item.kind == PathItemKind.lesson ? 72.0 : 64.0;

    Widget coin = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(color: edge, shape: BoxShape.circle),
      child: Container(
        decoration: BoxDecoration(color: face, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: locked || (completed && item.kind == PathItemKind.chest)
              ? AppColors.locked
              : Colors.white,
          size: size * 0.46,
        ),
      ),
    );

    if (item.isActive) {
      final ring = Container(
        width: size + 22,
        height: size + 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: face.withValues(alpha: 0.25),
            width: 8,
          ),
        ),
      );
      coin = Stack(
        alignment: Alignment.center,
        children: [
          if (pulse == null)
            ring
          else
            AnimatedBuilder(
              animation: pulse!,
              builder: (context, child) => Transform.scale(
                scale: 1 + 0.06 * pulse!.value,
                child: child,
              ),
              child: ring,
            ),
          coin,
        ],
      );
    } else {
      coin = SizedBox(
        width: size + 22,
        height: size + 22,
        child: Center(child: coin),
      );
    }

    final label = switch (item.kind) {
      PathItemKind.lesson => item.title,
      PathItemKind.exam => 'آزمون جامع',
      PathItemKind.chest => completed ? 'جعبه باز شد' : 'جعبه‌ی جایزه',
    };

    return Semantics(
      button: true,
      label: switch (item.kind) {
        PathItemKind.lesson => 'درس ${item.number}: ${item.title}',
        PathItemKind.exam => item.title,
        PathItemKind.chest => label,
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            coin,
            const SizedBox(height: 4),
            SizedBox(
              width: 170,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: item.isActive ? FontWeight.w900 : FontWeight.w700,
                  color: locked
                      ? AppColors.locked
                      : item.isActive
                          ? AppColors.ink
                          : AppColors.slate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Start sheet for a lesson or a review exam.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({
    required this.item,
    required this.courseId,
    required this.onLessonClosed,
  });

  final PathItemModel item;
  final String courseId;
  final VoidCallback onLessonClosed;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _curriculum = CurriculumRepository();
  final _sessions = SessionRepository();
  bool _busy = false;
  String? _error;

  bool get _isExam => widget.item.kind == PathItemKind.exam;

  Future<void> _run(Future<void> Function() action, String failure) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failure;
        });
      }
    }
  }

  Future<void> _start() => _run(() async {
        final item = widget.item;
        // Captured first: this sheet is closed before the lesson ends.
        final onClosed = widget.onLessonClosed;
        final session = _isExam
            ? await _sessions.startExamSession(widget.courseId, item.position)
            : await _sessions.startLessonSession(item.lessonId!);
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pop();
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => QuizScreen(
              unitTitle: session.lessonTitle,
              sessionId: session.sessionId,
              questions: session.exercises,
              notes: session.notes,
              energy: session.energy,
            ),
          ),
        );
        onClosed();
      }, _isExam ? 'شروع آزمون ناموفق بود' : 'شروع درس ناموفق بود');

  Future<void> _study() => _run(() async {
        final unit = await _curriculum.getUnit(widget.item.unitId);
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pop();
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WordStudyScreen(
              unitTitle: unit.title,
              words: unit.words,
            ),
          ),
        );
      }, 'بارگذاری مطالعه ناموفق بود');

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final face = _isExam ? AppColors.grape : AppColors.leaf;
    final edge = _isExam ? AppColors.grapeDark : AppColors.leafDark;
    final onFace = AppTheme.chunkyStyle(
      face: Colors.white,
      edge: Colors.white.withValues(alpha: 0.7),
      foreground: edge,
      textStyle: GoogleFonts.vazirmatn(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
    final subtitle = _isExam
        ? 'سؤال‌هایی از درس‌های ${item.fromNumber} تا ${item.toNumber}. '
            'برای قبولی ۷۰٪ لازم است و تا قبول نشوی درس بعدی باز نمی‌شود.'
        : item.unitTitle;
    final startLabel = _isExam
        ? (item.isCompleted ? 'دوباره آزمون بده' : 'شروع آزمون')
        : (item.isCompleted ? 'تمرین دوباره' : 'شروع درس');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: edge,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: GoogleFonts.vazirmatn(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.vazirmatn(
                  fontSize: 13,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
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
              ElevatedButton(
                style: onFace,
                onPressed: _busy ? null : _start,
                child: _busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: face,
                        ),
                      )
                    : Text(startLabel),
              ),
              if (!_isExam) ...[
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
                  onPressed: _busy ? null : _study,
                  child: const Text('اول واژه‌ها را مطالعه کن'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChestDialog extends StatelessWidget {
  const _ChestDialog({required this.rewards});

  final ChestRewards rewards;

  @override
  Widget build(BuildContext context) {
    final lines = <(IconData, Color, String)>[
      if (rewards.energy > 0)
        (Icons.bolt_rounded, AppColors.sky, '${rewards.energy} انرژی'),
      if (rewards.gems > 0)
        (Icons.diamond_rounded, AppColors.grape, '${rewards.gems} الماس'),
      if (rewards.xp > 0)
        (Icons.star_rounded, AppColors.sun, '${rewards.xp} امتیاز XP'),
      if (rewards.streakFreeze > 0)
        (Icons.ac_unit_rounded, AppColors.skyDark, 'یک یخ‌زدگی استریک'),
    ];
    return Dialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              size: 72,
              color: AppColors.flame,
            ),
            const SizedBox(height: 8),
            Text(
              'جعبه باز شد!',
              style: GoogleFonts.vazirmatn(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            for (final (icon, color, text) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('عالیه!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
