import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zaban/config/api_config.dart';
import 'package:zaban/services/token_storage.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({
    TokenStorage? tokenStorage,
    String? baseUrl,
  })  : _tokens = tokenStorage ?? TokenStorage(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStorage _tokens;
  final String baseUrl;

  TokenStorage get tokens => _tokens;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _authPost('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _authPost('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> me() async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw AuthApiException('وارد نشده‌اید');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $access',
        'Content-Type': 'application/json',
      },
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? bio,
  }) async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw AuthApiException('وارد نشده‌اید');
    }
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (bio != null) body['bio'] = bio;

    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me/profile'),
      headers: {
        'Authorization': 'Bearer $access',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateSettings({
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    bool? marketingEmailsEnabled,
  }) async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw AuthApiException('وارد نشده‌اید');
    }
    final body = <String, dynamic>{};
    if (notificationsEnabled != null) {
      body['notificationsEnabled'] = notificationsEnabled;
    }
    if (dailyReminderEnabled != null) {
      body['dailyReminderEnabled'] = dailyReminderEnabled;
    }
    if (marketingEmailsEnabled != null) {
      body['marketingEmailsEnabled'] = marketingEmailsEnabled;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me/settings'),
      headers: {
        'Authorization': 'Bearer $access',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<void> logout() async {
    final access = await _tokens.readAccessToken();
    if (access != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $access',
            'Content-Type': 'application/json',
          },
        );
      } catch (_) {
        // Still clear local tokens.
      }
    }
    await _tokens.clear();
  }

  Future<Map<String, dynamic>> _authPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = _decode(response);
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access != null && refresh != null) {
      await _tokens.saveTokens(accessToken: access, refreshToken: refresh);
    }
    return data;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic raw =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (raw is Map<String, dynamic>) return raw;
      return Map<String, dynamic>.from(raw as Map);
    }
    String message = 'خطای سرور (${response.statusCode})';
    if (raw is Map) {
      final msg = raw['message'];
      if (msg is String) message = msg;
      if (msg is List && msg.isNotEmpty) message = msg.first.toString();
    }
    throw AuthApiException(message);
  }
}
