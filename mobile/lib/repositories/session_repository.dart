import 'package:dio/dio.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/repositories/energy_repository.dart';
import 'package:zaban/services/api_client.dart';

class LessonSessionPayload {
  LessonSessionPayload({
    required this.sessionId,
    required this.expiresAt,
    required this.lessonTitle,
    required this.exercises,
    this.notes = const [],
    this.energy,
  });

  final String sessionId;
  final DateTime expiresAt;
  final String lessonTitle;
  final List<QuestionModel> exercises;

  /// Short teaching notes shown before practice (Markdown + LaTeX).
  final List<String> notes;

  /// Energy when the lesson started (nothing is burned until a page passes).
  final EnergySnapshot? energy;

  factory LessonSessionPayload.fromJson(Map<String, dynamic> json) {
    final lesson = Map<String, dynamic>.from(json['lesson'] as Map);
    return LessonSessionPayload(
      sessionId: json['sessionId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lessonTitle: lesson['title'] as String? ?? '',
      exercises: (lesson['exercises'] as List? ?? []).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Session payload has no answer — keep compatible with QuestionModel.
        map.putIfAbsent('answer', () => <String, dynamic>{});
        return QuestionModel.fromJson(map);
      }).toList(),
      notes: (lesson['notes'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      energy: json['energy'] is Map
          ? EnergySnapshot.fromJson(
              Map<String, dynamic>.from(json['energy'] as Map),
            )
          : null,
    );
  }
}

/// Server answer for one passed page: instant grade, energy and combo.
class StepResult {
  StepResult({
    required this.isCorrect,
    required this.gradingStatus,
    required this.energy,
    required this.comboStreak,
    required this.comboLength,
    this.solution,
    this.feedback,
    this.score,
    this.comboReward,
  });

  final bool isCorrect;

  /// `graded`, or `pending` / `ungraded` when AI grading is unavailable.
  final String gradingStatus;
  final String? solution;
  final String? feedback;
  final double? score;
  final EnergySnapshot? energy;
  final int comboStreak;
  final int comboLength;
  final ComboReward? comboReward;

  bool get graded => gradingStatus == 'graded';

  factory StepResult.fromJson(Map<String, dynamic> json) {
    final combo = json['combo'] is Map
        ? Map<String, dynamic>.from(json['combo'] as Map)
        : const <String, dynamic>{};
    final energy = json['energy'];
    final snapshot = energy is Map
        ? EnergySnapshot.fromJson(Map<String, dynamic>.from(energy))
        : null;
    return StepResult(
      isCorrect: json['isCorrect'] as bool? ?? false,
      gradingStatus: json['gradingStatus'] as String? ?? 'graded',
      solution: json['solution'] as String?,
      feedback: json['feedback'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      energy: snapshot,
      comboStreak: combo['streak'] as int? ?? snapshot?.comboStreak ?? 0,
      comboLength: combo['length'] as int? ?? 5,
      comboReward: combo['reward'] is Map
          ? ComboReward.fromJson(
              Map<String, dynamic>.from(combo['reward'] as Map),
            )
          : null,
    );
  }
}

/// Thrown when a page cannot be passed because energy ran out.
class OutOfEnergyException extends ApiException {
  OutOfEnergyException(super.message, {this.energy}) : super(statusCode: 403);
  final EnergySnapshot? energy;
}

class SessionSubmitResult {
  SessionSubmitResult({
    required this.correctCount,
    required this.totalCount,
    required this.scorePercent,
    required this.results,
    this.comboRewards = const [],
    this.energyBalance,
    this.xpGained = 0,
    this.streakBefore = 0,
    this.streakAfter = 0,
  });

  final int correctCount;
  final int totalCount;
  final int scorePercent;
  final List<Map<String, dynamic>> results;
  final List<ComboReward> comboRewards;
  final int? energyBalance;
  final int xpGained;

  /// Daily streak (days) before and after this lesson.
  final int streakBefore;
  final int streakAfter;

  bool get streakGrew => streakAfter > streakBefore;

  factory SessionSubmitResult.fromJson(Map<String, dynamic> json) {
    final energy = json['energy'];
    final gam = json['gamification'] is Map
        ? Map<String, dynamic>.from(json['gamification'] as Map)
        : const <String, dynamic>{};
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
      xpGained: gam['xpGained'] as int? ?? 0,
      streakBefore: gam['streakBefore'] as int? ?? 0,
      streakAfter: gam['streakAfter'] as int? ?? 0,
    );
  }
}

class ComboReward {
  ComboReward({
    required this.streak,
    required this.tier,
    required this.energyAwarded,
  });

  /// Pages in a row that triggered it (5, 10, 15, ...).
  final int streak;

  /// 1 at 5 in a row, 2 at 10, ... (bigger tier = bigger reward).
  final int tier;
  final int energyAwarded;

  factory ComboReward.fromJson(Map<String, dynamic> json) {
    return ComboReward(
      streak: json['streak'] as int? ?? 0,
      tier: json['tier'] as int? ?? 1,
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

  /// Pass one page: a question ([exerciseId] + [response]) or a lesson
  /// notes page ([page], e.g. `note:0`). Burns one energy on the server.
  Future<StepResult> step({
    required String sessionId,
    String? exerciseId,
    Map<String, dynamic>? response,
    String? page,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/sessions/$sessionId/steps',
        data: {
          if (exerciseId != null) 'exerciseId': exerciseId,
          if (exerciseId != null) 'response': response ?? <String, dynamic>{},
          if (page != null) 'page': page,
        },
      );
      return StepResult.fromJson(res.data ?? {});
    } on DioException catch (e) {
      final data = e.response?.data;
      final nested = data is Map ? data['message'] : null;
      final body = nested is Map ? nested : data;
      if (body is Map && body['code'] == 'INSUFFICIENT_ENERGY') {
        final energy = body['energy'];
        throw OutOfEnergyException(
          ApiClient.messageFrom(e),
          energy: energy is Map
              ? EnergySnapshot.fromJson(Map<String, dynamic>.from(energy))
              : null,
        );
      }
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
