import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/screens/auth/login_screen.dart';
import 'package:zaban/screens/path/learning_path_screen.dart';
import 'package:zaban/services/token_storage.dart';
import 'package:zaban/theme/app_theme.dart';

/// Decides between Login and Learning Path based on stored token.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = TokenStorage();
  bool _loading = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await _storage.hasAccessToken();
    if (!mounted) return;
    setState(() {
      _signedIn = has;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    if (_signedIn) {
      return const LearningPathScreen();
    }

    return LoginScreen(
      onLoggedIn: () => setState(() => _signedIn = true),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFC), AppColors.mist, AppColors.mistDeep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'زبان',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
