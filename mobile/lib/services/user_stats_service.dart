import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zaban/models/user_stats_model.dart';
import 'package:zaban/services/api_client.dart';

class UserStatsService extends ChangeNotifier {
  UserStatsService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;
  UserStatsModel? _stats;
  bool _loading = false;
  String? _error;

  UserStatsModel? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  int get hearts => _stats?.hearts ?? 0;
  int get gems => _stats?.gems ?? 0;
  int get streak => _stats?.streak ?? 0;
  bool get isSuper => _stats?.isSuper ?? false;

  Future<UserStatsModel> fetchStats() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/user-stats');
      _stats = UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      _loading = false;
      notifyListeners();
      return _stats!;
    } on DioException catch (e) {
      _loading = false;
      _error = _mapError(e, 'دریافت آمار با خطا مواجه شد');
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<UserStatsModel> decreaseHeart() async {
    try {
      final response = await _api.dio.post('/user-stats/decrease-heart');
      _stats = UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
      return _stats!;
    } on DioException catch (e) {
      throw Exception(_mapError(e, 'کم کردن قلب با خطا مواجه شد'));
    }
  }

  Future<UserStatsModel> completeUnit() async {
    try {
      final response = await _api.dio.post('/user-stats/complete-unit');
      _stats = UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
      return _stats!;
    } on DioException catch (e) {
      throw Exception(_mapError(e, 'ثبت اتمام یونیت با خطا مواجه شد'));
    }
  }

  Future<UserStatsModel> refillHearts() async {
    try {
      final response = await _api.dio.post('/user-stats/refill-hearts');
      _stats = UserStatsModel.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
      return _stats!;
    } on DioException catch (e) {
      throw Exception(_mapError(e, 'ترمیم قلب‌ها با خطا مواجه شد'));
    }
  }

  void markSuperActive() {
    if (_stats == null) return;
    _stats = UserStatsModel(
      id: _stats!.id,
      userId: _stats!.userId,
      hearts: _stats!.hearts,
      gems: _stats!.gems,
      streak: _stats!.streak,
      lastActivityDate: _stats!.lastActivityDate,
      hasActiveSubscription: true,
      infiniteHearts: true,
    );
    notifyListeners();
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

/// Shared singleton for app-wide stats (header + quiz).
final userStatsService = UserStatsService();
