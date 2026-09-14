import 'package:dio/dio.dart';
import 'package:zaban/models/user_model.dart';
import 'package:zaban/services/api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<void> requestOtp({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      await _api.dio.post(
        '/auth/request-otp',
        data: {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'ارسال کد با خطا مواجه شد');
    }
  }

  Future<UserModel> verifyOtp({
    required String code,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final response = await _api.dio.post(
        '/auth/verify-otp',
        data: {
          'code': code,
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      final token = response.data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('توکن دریافت نشد');
      }

      await _api.saveToken(token);
      return getMe();
    } on DioException catch (e) {
      throw _mapError(e, 'کد وارد شده نامعتبر است');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _api.dio.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _api.clearToken();
      }
      throw _mapError(e, 'دریافت اطلاعات کاربر با خطا مواجه شد');
    }
  }

  Future<void> logout() => _api.clearToken();

  Future<bool> isLoggedIn() => _api.hasToken();

  Exception _mapError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return Exception(message.join('\n'));
      }
      return Exception(message.toString());
    }
    return Exception(fallback);
  }
}
