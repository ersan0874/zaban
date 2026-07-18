import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaban/screens/path/learning_path_screen.dart';
import 'package:zaban/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ZabanApp());
}

class ZabanApp extends StatelessWidget {
  const ZabanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'زبان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LearningPathScreen(),
    );
  }
}
