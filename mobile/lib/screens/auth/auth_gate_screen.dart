import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/user_model.dart';
import 'package:zaban/screens/auth/login_screen.dart';
import 'package:zaban/screens/path/learning_path_screen.dart';
import 'package:zaban/screens/placement/placement_test_screen.dart';
import 'package:zaban/services/auth_service.dart';
import 'package:zaban/theme/app_theme.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) {
        _go(const LoginScreen());
        return;
      }

      final user = await _authService.getMe();
      _routeByUser(user);
    } catch (_) {
      await _authService.logout();
      _go(const LoginScreen());
    }
  }

  void _routeByUser(UserModel user) {
    if (user.needsPlacementTest) {
      _go(const PlacementTestScreen());
    } else {
      _go(const LearningPathScreen());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFC), AppColors.mist, Color(0xFFE5F0F2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.tealDeep),
              const SizedBox(height: 20),
              Text(
                'در حال بارگذاری...',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
