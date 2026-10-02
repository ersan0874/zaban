import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaban/screens/auth/auth_gate.dart';
import 'package:zaban/services/app_settings.dart';
import 'package:zaban/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  runApp(const ZabanApp());
}

class ZabanApp extends StatelessWidget {
  const ZabanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'زبان',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        // Persian UI: the whole app is right-to-left (Latin words and
        // numbers keep their own direction through the text engine).
        builder: (context, child) {
          // Neutral colors follow the resolved brightness; screens read
          // AppColors.* at build time, so this must happen before them.
          final dark = Theme.of(context).brightness == Brightness.dark;
          AppColors.current =
              dark ? AppColors.darkPalette : AppColors.lightPalette;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  dark ? Brightness.light : Brightness.dark,
            ),
          );
          // Screens read AppColors at build time; a new key rebuilds them all
          // when the theme flips (the learner lands back on the home tab).
          return KeyedSubtree(
            key: ValueKey(dark),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}
