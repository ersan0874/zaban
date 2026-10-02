import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/widgets/math_text.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('inline formulas keep reading order in RTL text', (tester) async {
    tester.view.physicalSize = const Size(2400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathText(r'اگر $a$ و $bb$ باشد، آنگاه $ccc$ است.'),
        ),
      ),
    );
    final xs = find
        .byType(Math)
        .evaluate()
        .map((e) => tester.getCenter(find.byWidget(e.widget)).dx)
        .toList();
    // RTL: the first formula is rightmost.
    expect(xs[0], greaterThan(xs[1]));
    expect(xs[1], greaterThan(xs[2]));
  });
}
