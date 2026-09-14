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
  });

  final int balance;
  final int cap;
  final int regenIntervalMinutes;
  final int lessonCost;
  final DateTime? nextRegenAt;
  final int? millisUntilNextRegen;

  factory EnergySnapshot.fromJson(Map<String, dynamic> json) {
    return EnergySnapshot(
      balance: json['balance'] as int? ?? 0,
      cap: json['cap'] as int? ?? 25,
      regenIntervalMinutes: json['regenIntervalMinutes'] as int? ?? 5,
      lessonCost: json['lessonCost'] as int? ?? 1,
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
