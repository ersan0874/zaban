import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/data/sample_data.dart';
import 'package:zaban/models/path_node_model.dart';
import 'package:zaban/screens/quiz/quiz_screen.dart';
import 'package:zaban/screens/study/word_study_screen.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/subscription_service.dart';
import 'package:zaban/services/user_stats_service.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/shop_bottom_sheet.dart';
import 'package:zaban/widgets/stats_header_bar.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final UserStatsService _statsService = userStatsService;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _statsService.fetchStats().catchError((_) {});
    subscriptionService.fetchStatus().catchError((_) {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        statsService: _statsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodes = SampleData.pathNodes;

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
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          'زبان',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const SuperSubscriptionScreen(),
                                ),
                              ).then((_) {
                                _statsService.fetchStats().catchError((_) {});
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'SUPER',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مسیر یادگیری واژگان کنکور ارشد',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StatsHeaderBar(statsService: _statsService),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
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
                ),
              ),
            ],
          ),
        ),
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

class _UnitActionSheet extends StatelessWidget {
  const _UnitActionSheet({
    required this.node,
    required this.statsService,
  });

  final PathNodeModel node;
  final UserStatsService statsService;

  Future<void> _startQuiz(BuildContext context) async {
    Navigator.pop(context);

    if (!statsService.isSuper && statsService.hearts <= 0) {
      await showShopBottomSheet(
        context,
        statsService: statsService,
        message: 'برای شروع آزمون به قلب نیاز داری!',
      );
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          unitTitle: node.title,
          questions: SampleData.questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WordStudyScreen(
                      unitTitle: node.title,
                      words: SampleData.words,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chrome_reader_mode_rounded),
              label: const Text('شروع مطالعه'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _startQuiz(context),
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('شروع آزمون'),
            ),
          ),
        ],
      ),
    );
  }
}
