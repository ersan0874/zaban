import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/late_grades_repository.dart';
import 'package:zaban/widgets/late_grades_sheet.dart';
import 'package:zaban/widgets/note_content.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders a Markdown table with LaTeX cells', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const NoteContent(
          '| شکل | مساحت |\n|---|---|\n| دایره | \$\\pi r^2\$ |\n| مربع | \$a^2\$ |',
        ),
      ),
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('دایره'), findsOneWidget);
    expect(find.byType(Math), findsNWidgets(2));
  });

  testWidgets('renders headings, bullets and figure placeholders',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const NoteContent(
          '## قانون فیثاغورس\n- ضلع‌ها: \$a, b\$\n- وتر: \$c\$\n[figure: right triangle]',
        ),
      ),
    );
    expect(find.text('قانون فیثاغورس'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.text('right triangle'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
  });

  test('late grade notice parses API json', () {
    final n = LateGradeNotice.fromJson({
      'attemptId': 'a1',
      'lessonTitle': 'درس',
      'question': 'سؤال',
      'isCorrect': true,
      'score': 1,
      'feedback': 'آفرین',
    });
    expect(n.score, 1.0);
    expect(n.isCorrect, isTrue);
  });

  testWidgets('late grades sheet lists notices with score', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LateGradesSheet(
            notices: [
              LateGradeNotice(
                attemptId: 'a1',
                lessonTitle: 'معادله',
                question: r'حل کن: $2x+3=11$',
                isCorrect: true,
                score: 0.8,
                feedback: 'خوب بود',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('خوب بود'), findsOneWidget);
  });
}
