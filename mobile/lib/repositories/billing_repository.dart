import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class BillingSnapshot {
  BillingSnapshot({
    this.subscription,
    required this.purchases,
  });

  final SubscriptionInfo? subscription;
  final List<PurchaseInfo> purchases;

  factory BillingSnapshot.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    return BillingSnapshot(
      subscription: sub != null
          ? SubscriptionInfo.fromJson(sub as Map<String, dynamic>)
          : null,
      purchases: (json['purchases'] as List<dynamic>? ?? [])
          .map((p) => PurchaseInfo.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubscriptionInfo {
  SubscriptionInfo({
    required this.plan,
    required this.expiresAt,
    required this.active,
  });

  final String plan;
  final DateTime expiresAt;
  final bool active;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      active: json['active'] as bool? ?? false,
    );
  }
}

class PurchaseInfo {
  PurchaseInfo({
    required this.id,
    required this.productId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String status;
  final DateTime createdAt;

  factory PurchaseInfo.fromJson(Map<String, dynamic> json) {
    return PurchaseInfo(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class BillingRepository {
  BillingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<BillingSnapshot> getMe() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/billing/me');
      return BillingSnapshot.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String receipt,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/billing/verify',
        data: {
          'productId': productId,
          'platform': 'web_test',
          'receipt': receipt,
        },
      );
      return res.data ?? {};
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
