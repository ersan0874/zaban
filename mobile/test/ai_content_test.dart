import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/repositories/session_repository.dart';
import 'package:zaban/screens/quiz/modules/exercise_modules.dart';
import 'package:zaban/screens/quiz/quiz_screen.dart';
import 'package:zaban/widgets/math_text.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

QuestionModel _q(String type, Map<String, dynamic> content) => QuestionModel(
      id: 'q-$type',
      type: type,
      prompt: 'دستور',
      content: content,
      answer: const {},
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('detectTextDirection', () {
    test('uses the first strong character', () {
      expect(detectTextDirection('سلام world'), TextDirection.rtl);
      expect(detectTextDirection('Hello دنیا'), TextDirection.ltr);
      expect(detectTextDirection(r'$x^2$ برابر است'), TextDirection.rtl);
    });
  });

  testWidgets('MathText renders inline and display LaTeX', (tester) async {
    await tester.pumpWidget(
      _wrap(const MathText(r'مساحت دایره $\pi r^2$ است: $$a^2+b^2=c^2$$')),
    );
    expect(find.byType(Math), findsNWidgets(2));
  });

  testWidgets('MathText keeps plain text as Text', (tester) async {
    await tester.pumpWidget(_wrap(const MathText('فقط متن')));
    expect(find.byType(Math), findsNothing);
    expect(find.text('فقط متن'), findsOneWidget);
  });

  test('session payload parses lesson notes', () {
    final payload = LessonSessionPayload.fromJson({
      'sessionId': 's1',
      'expiresAt': '2026-10-02T10:00:00.000Z',
      'lesson': {
        'title': 'درس',
        'notes': ['نکته ۱', '  ', r'$x$'],
        'exercises': [],
      },
    });
    expect(payload.notes, ['نکته ۱', r'$x$']);
  });

  testWidgets('true/false module submits a boolean', (tester) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(
      _wrap(
        ExerciseModuleRouter(
          question: _q('true_false', {'statement': 'زمین گرد است'}),
          onSubmitResponse: (r) => sent = r,
        ),
      ),
    );
    await tester.tap(find.text('غلط'));
    await tester.pump();
    await tester.tap(find.text('ثبت و ادامه'));
    expect(sent, {'value': false});
  });

  testWidgets('multiple choice shows the AI question stem', (tester) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(
      _wrap(
        ExerciseModuleRouter(
          question: _q('multiple_choice', {
            'stem': 'معادل انگلیسی «شهرت» کدام است؟',
            'options': ['Renown', 'Persist'],
          }),
          onSubmitResponse: (r) => sent = r,
        ),
      ),
    );
    expect(find.text('معادل انگلیسی «شهرت» کدام است؟'), findsOneWidget);
    await tester.tap(find.text('Renown'));
    await tester.pump();
    await tester.tap(find.text('ثبت و ادامه'));
    expect(sent, {'correctOption': 'Renown'});
  });

  testWidgets('English cloze text is laid out left to right', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExerciseModuleRouter(
          question: _q('cloze_typing', {
            'text': 'There are four _____ types.',
            'blanks': [
              {'id': 'blank_1', 'position': 0},
            ],
          }),
          onSubmitResponse: (_) {},
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('There are four _____ types.'));
    expect(text.textDirection, TextDirection.ltr);
  });

  testWidgets('essay module submits text', (tester) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(
      _wrap(
        ExerciseModuleRouter(
          question: _q('essay', {'question': 'توضیح بده'}),
          onSubmitResponse: (r) => sent = r,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '  پاسخ من ');
    await tester.pump();
    await tester.tap(find.text('ثبت و ادامه'));
    expect(sent, {'text': 'پاسخ من'});
  });

  testWidgets('quiz shows notes before the first exercise', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          unitTitle: 'درس',
          sessionId: 's1',
          notes: const ['نکته اول'],
          questions: [
            _q('short_answer', {'question': 'پایتخت ایران؟'})
          ],
        ),
      ),
    );
    expect(find.text('نکته اول'), findsOneWidget);
    // Passing the notes page is a server step (energy), so only check the
    // button here; the step itself is covered by the API tests.
    expect(find.text('شروع تمرین'), findsOneWidget);
    expect(find.text('پایتخت ایران؟'), findsNothing);
  });
}
