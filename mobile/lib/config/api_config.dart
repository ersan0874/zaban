import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _tokenKey = 'access_token';

  /// Android emulator maps host localhost to 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Avoid dart:io so the same file compiles for web.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://localhost:3000/api';
    }
  }

  static String get tokenKey => _tokenKey;
}
