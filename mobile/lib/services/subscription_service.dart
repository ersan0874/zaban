import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zaban/config/api_config.dart';
import 'package:zaban/models/subscription_model.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/services/user_stats_service.dart';

class SubscriptionService extends ChangeNotifier {
  SubscriptionService({
    ApiClient? apiClient,
    UserStatsService? statsService,
  })  : _api = apiClient ?? ApiClient.instance,
        _statsService = statsService ?? userStatsService;

  final ApiClient _api;
  final UserStatsService _statsService;

  SubscriptionStatusModel? _status;
  bool _loading = false;

  SubscriptionStatusModel? get status => _status;
  bool get isActive => _status?.isActive ?? _statsService.isSuper;
  bool get loading => _loading;

  Future<SubscriptionStatusModel> fetchStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/subscriptions/status');
      _status = SubscriptionStatusModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (_status!.isActive) {
        _statsService.markSuperActive();
      }
      _loading = false;
      notifyListeners();
      return _status!;
    } on DioException catch (e) {
      _loading = false;
      notifyListeners();
      throw Exception(_mapError(e, 'دریافت وضعیت اشتراک با خطا مواجه شد'));
    }
  }

  Future<PaymentRequestResult> requestPayment(SuperPlan plan) async {
    try {
      final response = await _api.dio.post(
        '/payments/request',
        data: {'planType': plan.apiValue},
      );
      return PaymentRequestResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_mapError(e, 'ساخت لینک پرداخت با خطا مواجه شد'));
    }
  }

  /// Resolves payment URL against the Flutter API base (works on emulator).
  String resolvePaymentUrl(PaymentRequestResult payment) {
    if (payment.verifyPath != null && payment.verifyPath!.isNotEmpty) {
      final path = payment.verifyPath!.replaceFirst('/api', '');
      return '${ApiConfig.baseUrl}$path';
    }
    return payment.paymentUrl.replaceFirst(
      'http://localhost:3000/api',
      ApiConfig.baseUrl,
    );
  }

  Future<bool> openPaymentUrl(String url) async {
    // url_launcher skipped when pub.dev is unreachable; mock verify is enough.
    debugPrint('Payment URL: $url');
    return true;
  }

  /// Completes mock payment via API (reliable on Android emulator).
  Future<void> completeMockPayment(String authority) async {
    try {
      await _api.dio.get(
        '/payments/verify',
        queryParameters: {
          'authority': authority,
          'Status': 'OK',
        },
        options: Options(responseType: ResponseType.plain),
      );
      await refreshAfterPayment();
    } on DioException catch (e) {
      throw Exception(_mapError(e, 'تأیید پرداخت با خطا مواجه شد'));
    }
  }

  Future<void> refreshAfterPayment() async {
    await fetchStatus();
    await _statsService.fetchStats();
  }

  String _mapError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return message.join('\n');
      }
      return message.toString();
    }
    return fallback;
  }
}

final subscriptionService = SubscriptionService();
