import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class EnergySnapshot {
  EnergySnapshot({
    required this.balance,
    required this.cap,
    required this.regenIntervalMinutes,
    required this.lessonCost,
    this.nextRegenAt,
    this.millisUntilNextRegen,
    this.comboStreak = 0,
    this.unlimited = false,
  });

  final int balance;
  final int cap;
  final int regenIntervalMinutes;

  /// Energy burned per page passed.
  final int lessonCost;
  final int comboStreak;
  final bool unlimited;

  /// True when the next page cannot be paid for.
  bool get isEmpty => !unlimited && balance < lessonCost;
  final DateTime? nextRegenAt;
  final int? millisUntilNextRegen;

  factory EnergySnapshot.fromJson(Map<String, dynamic> json) {
    return EnergySnapshot(
      balance: json['balance'] as int? ?? 0,
      cap: json['cap'] as int? ?? 25,
      regenIntervalMinutes: json['regenIntervalMinutes'] as int? ?? 5,
      lessonCost: json['stepCost'] as int? ?? json['lessonCost'] as int? ?? 1,
      comboStreak: json['comboStreak'] as int? ?? 0,
      unlimited: json['unlimited'] as bool? ?? false,
      nextRegenAt: json['nextRegenAt'] != null
          ? DateTime.tryParse(json['nextRegenAt'] as String)
          : null,
      millisUntilNextRegen: json['millisUntilNextRegen'] as int?,
    );
  }
}

class EnergyRepository {
  EnergyRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<EnergySnapshot> getEnergy() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/energy');
      return EnergySnapshot.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
