import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/curriculum_repository.dart';
import 'package:zaban/repositories/mastery_repository.dart';
import 'package:zaban/screens/subscription/super_subscription_screen.dart';
import 'package:zaban/services/auth_api.dart';
import 'package:zaban/services/app_settings.dart';
import 'package:zaban/services/feedback_fx.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onLoggedOut,
    this.embedded = false,
  });

  final VoidCallback onLoggedOut;
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = AuthApi();
  final _curriculum = CurriculumRepository();
  final _mastery = MasteryRepository();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _email;
  String? _error;
  String? _level;
  double? _masteryScore;
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
      _level = me['level'] as String?;
      _name.text = profile?['displayName'] as String? ?? '';
      _bio.text = profile?['bio'] as String? ?? '';
      _notifications = settings?['notificationsEnabled'] as bool? ?? true;
      _dailyReminder = settings?['dailyReminderEnabled'] as bool? ?? true;

      try {
        final courses = await _curriculum.listCourses();
        if (courses.isNotEmpty) {
          final m = await _mastery.getCourseMastery(courses.first.id);
          _masteryScore = m.score;
        }
      } catch (_) {}
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

  String get _levelFa {
    switch (_level) {
      case 'beginner':
        return 'مبتدی';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'پیشرفته';
      default:
        return 'تعیین‌نشده';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _name.text.trim().isNotEmpty ? _name.text.trim() : (_email ?? '');
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Center(child: ZAvatar(name: displayName, size: 96)),
              const SizedBox(height: 12),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_email != null && _email != displayName)
                Text(
                  _email!,
                  textAlign: TextAlign.center,
                  style: AppTheme.latin(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ZStatTile(
                      icon: Icons.signal_cellular_alt_rounded,
                      color: AppColors.sky,
                      value: _levelFa,
                      label: 'سطح',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZStatTile(
                      icon: Icons.workspace_premium_rounded,
                      color: AppColors.sun,
                      value: _masteryScore != null
                          ? '${_masteryScore!.round()}%'
                          : '—',
                      label: 'تسلط دوره',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZCard(
                color: AppColors.ink,
                borderColor: AppColors.ink,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SuperSubscriptionScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.grape, AppColors.sky],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ارتقا به Super',
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'قلب نامحدود و تجربه بدون وقفه',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const ZSectionTitle('حساب من'),
              TextField(
                controller: _name,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'نام نمایشی'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'درباره من'),
              ),
              const ZSectionTitle('ظاهر و صدا'),
              ZCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'حالت تاریک',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: AppColors.isDark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.leaf,
                      onChanged: (v) => AppSettings.setTheme(
                        v ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                    Divider(height: 2, color: AppColors.line),
                    ValueListenableBuilder<bool>(
                      valueListenable: FeedbackFx.soundOn,
                      builder: (context, on, _) => SwitchListTile(
                        title: Text(
                          'صدا و لرزش',
                          style: GoogleFonts.vazirmatn(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        value: on,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.leaf,
                        onChanged: AppSettings.setSound,
                      ),
                    ),
                  ],
                ),
              ),
              const ZSectionTitle('اعلان‌ها'),
              ZCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'اعلان‌ها',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: _notifications,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.leaf,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                    Divider(height: 2, color: AppColors.line),
                    SwitchListTile(
                      title: Text(
                        'یادآوری روزانه',
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: _dailyReminder,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.leaf,
                      onChanged: (v) => setState(() => _dailyReminder = v),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: const Text('ذخیره'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: AppTheme.chunkyStyle(
                  face: AppColors.snow,
                  edge: AppColors.line,
                  border: AppColors.line,
                  foreground: AppColors.danger,
                ),
                onPressed: _logout,
                child: const Text('خروج از حساب'),
              ),
            ],
          );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: widget.embedded
            ? AppBar(
                automaticallyImplyLeading: false,
                title: const Text('پروفایل من'),
              )
            : AppBar(title: const Text('پروفایل')),
        body: body,
      ),
    );
  }
}
