class SubscriptionStatusModel {
  final bool isActive;
  final bool infiniteHearts;
  final String? planType;
  final DateTime? endDate;

  const SubscriptionStatusModel({
    required this.isActive,
    required this.infiniteHearts,
    this.planType,
    this.endDate,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    String? planType;
    DateTime? endDate;

    if (sub is Map<String, dynamic>) {
      planType = sub['planType'] as String?;
      final rawEnd = sub['endDate'];
      if (rawEnd is String) {
        endDate = DateTime.tryParse(rawEnd);
      }
    }

    return SubscriptionStatusModel(
      isActive: json['isActive'] as bool? ?? false,
      infiniteHearts: json['infiniteHearts'] as bool? ?? false,
      planType: planType,
      endDate: endDate,
    );
  }
}

class PaymentRequestResult {
  final String authority;
  final int amount;
  final String planType;
  final String paymentUrl;
  final String? verifyPath;

  const PaymentRequestResult({
    required this.authority,
    required this.amount,
    required this.planType,
    required this.paymentUrl,
    this.verifyPath,
  });

  factory PaymentRequestResult.fromJson(Map<String, dynamic> json) {
    return PaymentRequestResult(
      authority: json['authority'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      planType: json['planType'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
      verifyPath: json['verifyPath'] as String?,
    );
  }
}

enum SuperPlan {
  monthly,
  threeMonths,
  yearly;

  String get apiValue {
    switch (this) {
      case SuperPlan.monthly:
        return 'monthly';
      case SuperPlan.threeMonths:
        return 'three_months';
      case SuperPlan.yearly:
        return 'yearly';
    }
  }

  String get title {
    switch (this) {
      case SuperPlan.monthly:
        return '۱ ماهه';
      case SuperPlan.threeMonths:
        return '۳ ماهه';
      case SuperPlan.yearly:
        return '۱ ساله';
    }
  }

  String get priceLabel {
    switch (this) {
      case SuperPlan.monthly:
        return '۱۴۹٬۰۰۰';
      case SuperPlan.threeMonths:
        return '۳۴۹٬۰۰۰';
      case SuperPlan.yearly:
        return '۹۹۰٬۰۰۰';
    }
  }

  String? get badge {
    switch (this) {
      case SuperPlan.monthly:
        return null;
      case SuperPlan.threeMonths:
        return '٪۲۲ تخفیف';
      case SuperPlan.yearly:
        return 'به‌صرفه‌ترین';
    }
  }

  String get subtitle {
    switch (this) {
      case SuperPlan.monthly:
        return 'قلب بی‌نهایت برای ۳۰ روز';
      case SuperPlan.threeMonths:
        return '۹۰ روز دسترسی کامل';
      case SuperPlan.yearly:
        return 'یک سال بدون محدودیت';
    }
  }
}
