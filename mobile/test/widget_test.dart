import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Zaban app smoke test shows brand', (WidgetTester tester) async {
    // No saved token: the auth gate finishes loading and shows the brand.
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const ZabanApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('زبان'), findsWidgets);
  });
}
