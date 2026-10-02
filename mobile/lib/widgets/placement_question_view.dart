import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/chunky_tile.dart';

/// Collects a single multiple-choice answer without revealing correctness.
class PlacementQuestionView extends StatefulWidget {
  const PlacementQuestionView({
    super.key,
    required this.question,
    required this.onNext,
    required this.isLast,
  });

  final QuestionModel question;
  final ValueChanged<String> onNext;
  final bool isLast;

  @override
  State<PlacementQuestionView> createState() => _PlacementQuestionViewState();
}

class _PlacementQuestionViewState extends State<PlacementQuestionView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options;

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

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChunkyTile(
              selected: isSelected,
              onTap: () => setState(() => _selected = option),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Text(
                option,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        ElevatedButton(
          onPressed: _selected == null ? null : () => widget.onNext(_selected!),
          child: Text(
            widget.isLast ? 'ثبت نهایی' : 'سؤال بعدی',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
