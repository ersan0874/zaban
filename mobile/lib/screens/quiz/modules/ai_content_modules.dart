import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/chunky_tile.dart';
import 'package:zaban/widgets/math_text.dart';

/// Called with the learner's answer payload for the server grader.
typedef AiExerciseCallback = void Function(Map<String, dynamic> response);

/// Statement / question box for AI-generated content (may contain LaTeX).
class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.line, width: 2),
      ),
      child: MathText(
        text,
        style: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.6,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class TrueFalseModule extends StatefulWidget {
  const TrueFalseModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final AiExerciseCallback onSubmitResponse;

  @override
  State<TrueFalseModule> createState() => _TrueFalseModuleState();
}

class _TrueFalseModuleState extends State<TrueFalseModule> {
  bool? _selected;

  Widget _choice(bool value, String label, IconData icon, Color color) {
    final selected = _selected == value;
    return ChunkyTile(
      selected: selected,
      onTap: () => setState(() => _selected = value),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.vazirmatn(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statement = widget.question.content['statement']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MathText(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
            child: SingleChildScrollView(child: _ContentCard(text: statement))),
        const SizedBox(height: 20),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _choice(
                true,
                'درست',
                Icons.check_circle_rounded,
                AppColors.leaf,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _choice(
                false,
                'غلط',
                Icons.cancel_rounded,
                AppColors.coral,
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => widget.onSubmitResponse({'value': _selected}),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Short answer (exact match) and essay (graded by AI on the server).
class OpenAnswerModule extends StatefulWidget {
  const OpenAnswerModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
    this.essay = false,
  });

  final QuestionModel question;
  final AiExerciseCallback onSubmitResponse;
  final bool essay;

  @override
  State<OpenAnswerModule> createState() => _OpenAnswerModuleState();
}

class _OpenAnswerModuleState extends State<OpenAnswerModule> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question.content['question']?.toString() ?? '';
    final empty = _controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MathText(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ContentCard(text: question),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  minLines: widget.essay ? 5 : 1,
                  maxLines: widget.essay ? 10 : 1,
                  textDirection: detectTextDirection(
                    _controller.text.isEmpty ? question : _controller.text,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.essay ? 'پاسخ تشریحی شما' : 'پاسخ کوتاه',
                    alignLabelWithHint: widget.essay,
                  ),
                ),
                if (widget.essay) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.grape,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'پاسخت را هوش مصنوعی تصحیح می‌کند و در پایان درس بازخورد می‌بینی.',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: empty
              ? null
              : () => widget.onSubmitResponse({
                    'text': _controller.text.trim(),
                  }),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
