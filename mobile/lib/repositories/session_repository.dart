import 'package:dio/dio.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/services/api_client.dart';

class LessonSessionPayload {
  LessonSessionPayload({
    required this.sessionId,
    required this.expiresAt,
    required this.lessonTitle,
    required this.exercises,
  });

  final String sessionId;
  final DateTime expiresAt;
  final String lessonTitle;
  final List<QuestionModel> exercises;

  factory LessonSessionPayload.fromJson(Map<String, dynamic> json) {
    final lesson = Map<String, dynamic>.from(json['lesson'] as Map);
    return LessonSessionPayload(
      sessionId: json['sessionId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lessonTitle: lesson['title'] as String? ?? '',
      exercises: (lesson['exercises'] as List? ?? [])
          .map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            // Session payload has no answer — keep compatible with QuestionModel.
            map.putIfAbsent('answer', () => <String, dynamic>{});
            return QuestionModel.fromJson(map);
          })
          .toList(),
    );
  }
}

class SessionSubmitResult {
  SessionSubmitResult({
    required this.correctCount,
    required this.totalCount,
    required this.scorePercent,
    required this.results,
    this.comboRewards = const [],
    this.energyBalance,
  });

  final int correctCount;
  final int totalCount;
  final int scorePercent;
  final List<Map<String, dynamic>> results;
  final List<ComboReward> comboRewards;
  final int? energyBalance;

  factory SessionSubmitResult.fromJson(Map<String, dynamic> json) {
    final energy = json['energy'];
    return SessionSubmitResult(
      correctCount: json['correctCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      scorePercent: json['scorePercent'] as int? ?? 0,
      results: (json['results'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      comboRewards: (json['comboRewards'] as List? ?? [])
          .map((e) => ComboReward.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      energyBalance: energy is Map ? energy['balance'] as int? : null,
    );
  }
}

class ComboReward {
  ComboReward({
    required this.atAnswerIndex,
    required this.streak,
    required this.energyAwarded,
  });

  final int atAnswerIndex;
  final int streak;
  final int energyAwarded;

  factory ComboReward.fromJson(Map<String, dynamic> json) {
    return ComboReward(
      atAnswerIndex: json['atAnswerIndex'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      energyAwarded: json['energyAwarded'] as int? ?? 0,
    );
  }
}

class SessionRepository {
  SessionRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<LessonSessionPayload> startLessonSession(String lessonId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/lessons/$lessonId/sessions',
      );
      return LessonSessionPayload.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SessionSubmitResult> submit({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/sessions/$sessionId/submit',
        data: {'answers': answers},
      );
      return SessionSubmitResult.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
