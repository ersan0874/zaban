import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/screens/path/learning_path_screen.dart';
import 'package:zaban/screens/placement/placement_test_screen.dart';
import 'package:zaban/services/auth_service.dart';
import 'package:zaban/theme/app_theme.dart';

enum _LoginMode { phone, email }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();

  _LoginMode _mode = _LoginMode.phone;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final value = _identifierController.text.trim();
      if (_mode == _LoginMode.phone) {
        await _authService.requestOtp(phoneNumber: value);
      } else {
        await _authService.requestOtp(email: value);
      }

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final identifier = _identifierController.text.trim();
      final code = _otpController.text.trim();

      final user = await _authService.verifyOtp(
        code: code,
        phoneNumber: _mode == _LoginMode.phone ? identifier : null,
        email: _mode == _LoginMode.email ? identifier : null,
      );

      if (!mounted) return;

      final nextScreen = user.needsPlacementTest
          ? const PlacementTestScreen()
          : const LearningPathScreen();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'ورود به زبان',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'با شماره موبایل یا ایمیل وارد شوید',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 15,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 32),
                SegmentedButton<_LoginMode>(
                  segments: [
                    ButtonSegment(
                      value: _LoginMode.phone,
                      label: Text(
                        'موبایل',
                        style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ButtonSegment(
                      value: _LoginMode.email,
                      label: Text(
                        'ایمیل',
                        style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _otpSent
                      ? null
                      : (selection) {
                          setState(() {
                            _mode = selection.first;
                            _identifierController.clear();
                          });
                        },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _identifierController,
                  enabled: !_otpSent && !_loading,
                  keyboardType: _mode == _LoginMode.phone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: _mode == _LoginMode.phone
                        ? 'شماره موبایل'
                        : 'ایمیل',
                    hintText: _mode == _LoginMode.phone
                        ? '09123456789'
                        : 'user@example.com',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'کد تأیید',
                      hintText: '1234',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (!_otpSent)
                  ElevatedButton(
                    onPressed: _loading ? null : _requestOtp,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ارسال کد',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'تأیید و ورود',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _error = null;
                            });
                          },
                    child: Text(
                      'تغییر شماره / ایمیل',
                      style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
