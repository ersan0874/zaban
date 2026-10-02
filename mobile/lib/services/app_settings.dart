import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zaban/services/feedback_fx.dart';

/// Device-level preferences: theme and sound. Kept in secure storage so no
/// extra plugin is needed; every read/write is best effort.
class AppSettings {
  AppSettings._();

  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'pref_theme';
  static const _soundKey = 'pref_sound';

  /// `light`, `dark` or `system`.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final theme = await _storage.read(key: _themeKey);
      themeMode.value = switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      FeedbackFx.soundOn.value = (await _storage.read(key: _soundKey)) != 'off';
    } catch (_) {}
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (_) {}
  }

  static Future<void> setSound(bool on) async {
    FeedbackFx.soundOn.value = on;
    try {
      await _storage.write(key: _soundKey, value: on ? 'on' : 'off');
    } catch (_) {}
  }
}
