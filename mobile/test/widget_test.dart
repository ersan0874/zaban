import 'package:flutter_test/flutter_test.dart';
import 'package:zaban/main.dart';

void main() {
  testWidgets('Zaban app smoke test shows brand', (WidgetTester tester) async {
    await tester.pumpWidget(const ZabanApp());
    await tester.pump();

    expect(find.text('زبان'), findsWidgets);
  });
}
