import 'package:dio/dio.dart';
import 'package:zaban/config/api_config.dart';
import 'package:zaban/services/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Shared Dio client with Bearer token + refresh-on-401.
class ApiClient {
  ApiClient({
    TokenStorage? tokenStorage,
    String? baseUrl,
  }) : _tokens = tokenStorage ?? TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokens.readAccessToken();
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = error.requestOptions;
              req.extra['retried'] = true;
              final access = await _tokens.readAccessToken();
              req.headers['Authorization'] = 'Bearer $access';
              try {
                final response = await _dio.fetch(req);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _tokens;
  bool _refreshing = false;

  Dio get dio => _dio;
  TokenStorage get tokens => _tokens;

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _tokens.readRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final res = await Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl),
      ).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data ?? {};
      final access = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (access == null || newRefresh == null) return false;
      await _tokens.saveTokens(
        accessToken: access,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  static String messageFrom(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'اتصال به سرور برقرار نشد. اینترنت یا سرور را چک کنید.';
    }
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      final code = data['code']?.toString();
      if (code == 'DIAGNOSTIC_REQUIRED') {
        return 'اول آزمون بازگشت را انجام بده، بعد درس جدید شروع کن.';
      }
      if (msg is String) return msg;
      if (msg is Map) {
        final code = msg['code']?.toString();
        if (code == 'INSUFFICIENT_ENERGY') {
          return 'انرژی کافی نیست. کمی صبر کن تا شارژ شود.';
        }
        if (code == 'DIAGNOSTIC_REQUIRED') {
          return 'اول آزمون بازگشت را انجام بده، بعد درس جدید شروع کن.';
        }
        if (msg['message'] is String) return msg['message'] as String;
      }
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return 'خطای سرور (${e.response?.statusCode ?? '؟'})';
  }
}
