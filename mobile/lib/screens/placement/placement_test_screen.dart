import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/screens/home/home_shell.dart';
import 'package:zaban/services/placement_test_service.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/placement_question_view.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  final PlacementTestService _service = PlacementTestService();

  List<QuestionModel> _questions = [];
  final List<Map<String, dynamic>> _answers = [];
  int _index = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _service.fetchQuestions();
      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'سوالی برای آزمون تعیین سطح یافت نشد';
        });
        return;
      }

      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onAnswerSelected(String answer) {
    final question = _questions[_index];
    _answers.add({
      'questionId': question.id,
      'answer': answer,
    });

    if (_index >= _questions.length - 1) {
      _submit();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _service.submitAnswers(_answers);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تعیین سطح انجام شد',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'سطح شما ${result.levelLabel} تعیین شد!\n'
            'نمره: ${result.score} از ${result.total} (${result.percentage}٪)',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              height: 1.6,
              color: AppColors.inkSoft,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'رفتن به مسیر یادگیری',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
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
          child: _loading
              ? _buildLoading()
              : _error != null && _questions.isEmpty
                  ? _buildError()
                  : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.tealDeep),
          const SizedBox(height: 16),
          Text(
            'در حال بارگذاری آزمون...',
            style: GoogleFonts.vazirmatn(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              _error ?? 'خطای ناشناخته',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(color: AppColors.danger),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadQuestions();
              },
              child: Text(
                'تلاش مجدد',
                style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final total = _questions.length;
    final current = _questions[_index];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            children: [
              Text(
                'آزمون تعیین سطح',
                style: GoogleFonts.vazirmatn(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'پاسخ درست را انتخاب کنید',
                style: GoogleFonts.vazirmatn(
                  fontSize: 14,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / total,
                    minHeight: 6,
                    backgroundColor: AppColors.mistDeep,
                    color: AppColors.tealDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(color: AppColors.danger),
            ),
          ),
        Expanded(
          child: _submitting
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.tealDeep),
                      const SizedBox(height: 16),
                      Text(
                        'در حال محاسبه سطح...',
                        style: GoogleFonts.vazirmatn(color: AppColors.slate),
                      ),
                    ],
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Padding(
                    key: ValueKey(current.id),
                    padding: const EdgeInsets.all(24),
                    child: PlacementQuestionView(
                      question: current,
                      isLast: _index >= total - 1,
                      onNext: _onAnswerSelected,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
