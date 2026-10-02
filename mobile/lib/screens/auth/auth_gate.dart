import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/user_model.dart';
import 'package:zaban/screens/auth/login_screen.dart';
import 'package:zaban/screens/home/home_shell.dart';
import 'package:zaban/screens/placement/placement_test_screen.dart';
import 'package:zaban/services/auth_api.dart';
import 'package:zaban/services/token_storage.dart';
import 'package:zaban/theme/app_theme.dart';

/// Decides between Login, Placement, and Home based on token + level.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = TokenStorage();
  final _api = AuthApi();
  bool _loading = true;
  bool _signedIn = false;
  bool _needsPlacement = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final has = await _storage.hasAccessToken();
    if (!has) {
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _needsPlacement = false;
        _loading = false;
      });
      return;
    }

    try {
      final me = await _api.me();
      final user = UserModel.fromJson(me);
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _needsPlacement = user.needsPlacementTest;
        _loading = false;
      });
    } catch (_) {
      await _storage.clear();
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _needsPlacement = false;
        _loading = false;
      });
    }
  }

  Future<void> _onLoggedIn() async {
    setState(() => _loading = true);
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.teal),
              const SizedBox(height: 16),
              Text(
                'در حال بارگذاری…',
                style: GoogleFonts.vazirmatn(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );
    }

    if (!_signedIn) {
      return LoginScreen(onLoggedIn: _onLoggedIn);
    }

    if (_needsPlacement) {
      return PlacementTestScreen(
        onCompleted: () {
          setState(() => _needsPlacement = false);
        },
      );
    }

    return const HomeShell();
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
        color: AppColors.snow,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.leafDark,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.leaf,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Text(
                          'ز',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'زبان',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.leaf,
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
