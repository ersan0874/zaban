import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/services/auth_api.dart';
import 'package:zaban/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLoggedOut});

  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = AuthApi();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _email;
  String? _error;
  bool _notifications = true;
  bool _dailyReminder = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await _api.me();
      final profile = me['profile'] as Map<String, dynamic>?;
      final settings = me['settings'] as Map<String, dynamic>?;
      _email = me['email'] as String?;
      _name.text = profile?['displayName'] as String? ?? '';
      _bio.text = profile?['bio'] as String? ?? '';
      _notifications = settings?['notificationsEnabled'] as bool? ?? true;
      _dailyReminder = settings?['dailyReminderEnabled'] as bool? ?? true;
    } on AuthApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'بارگذاری پروفایل ناموفق بود';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.updateProfile(
        displayName: _name.text.trim(),
        bio: _bio.text.trim(),
      );
      await _api.updateSettings(
        notificationsEnabled: _notifications,
        dailyReminderEnabled: _dailyReminder,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ذخیره شد', style: GoogleFonts.vazirmatn()),
        ),
      );
    } on AuthApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('پروفایل', style: GoogleFonts.vazirmatn()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_email != null)
                  Text(
                    _email!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: AppColors.slate),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: 'نام نمایشی',
                    labelStyle: GoogleFonts.vazirmatn(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'درباره من',
                    labelStyle: GoogleFonts.vazirmatn(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('اعلان‌ها', style: GoogleFonts.vazirmatn()),
                  value: _notifications,
                  activeThumbColor: AppColors.teal,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                SwitchListTile(
                  title: Text(
                    'یادآوری روزانه',
                    style: GoogleFonts.vazirmatn(),
                  ),
                  value: _dailyReminder,
                  activeThumbColor: AppColors.teal,
                  onChanged: (v) => setState(() => _dailyReminder = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: GoogleFonts.vazirmatn(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    'ذخیره',
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _logout,
                  child: Text(
                    'خروج از حساب',
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
    );
  }
}
