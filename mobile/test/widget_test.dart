import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/quiz/answer_feedback_bar.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/mascot.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: child)),
      ),
    );

StepResult _step({required bool ok, String? solution}) => StepResult.fromJson({
      'isCorrect': ok,
      'solution': solution,
      'gradingStatus': 'graded',
      'combo': {'streak': ok ? 3 : 0, 'length': 5},
    });

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('feedback bar praises a correct answer', (tester) async {
    var continued = false;
    await tester.pumpWidget(_wrap(AnswerFeedbackBar(
      result: _step(ok: true),
      onContinue: () => continued = true,
    )));
    await tester.pumpAndSettle();
    expect(find.text('ادامه'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    expect(continued, isTrue);
  });

  testWidgets('feedback bar shows the right answer after a mistake',
      (tester) async {
    await tester.pumpWidget(_wrap(AnswerFeedbackBar(
      result: _step(ok: false, solution: 'abandon'),
      onContinue: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('پاسخ درست:'), findsOneWidget);
    expect(find.text('فهمیدم'), findsOneWidget);
  });

  test('step result reads combo reward and energy', () {
    final r = StepResult.fromJson({
      'isCorrect': true,
      'gradingStatus': 'graded',
      'energy': {'balance': 20, 'cap': 25, 'stepCost': 1, 'comboStreak': 5},
      'combo': {
        'streak': 5,
        'length': 5,
        'reward': {'streak': 5, 'tier': 1, 'energyAwarded': 2},
      },
    });
    expect(r.comboReward?.energyAwarded, 2);
    expect(r.energy?.balance, 20);
    expect(r.energy?.isEmpty, isFalse);
  });

  testWidgets('mascot renders in every mood', (tester) async {
    for (final mood in MascotMood.values) {
      await tester.pumpWidget(_wrap(Mascot(mood: mood, bounce: false)));
      expect(find.byType(Mascot), findsOneWidget);
    }
  });

  test('dark palette swaps neutrals but keeps brand colors', () {
    AppColors.current = AppColors.darkPalette;
    expect(AppColors.isDark, isTrue);
    expect(AppColors.snow, isNot(Colors.white));
    expect(AppColors.leaf, const Color(0xFF58C322));
    AppColors.current = AppColors.lightPalette;
  });
}
