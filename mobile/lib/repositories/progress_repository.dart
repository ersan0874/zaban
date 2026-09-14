import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class ProgressItem {
  ProgressItem({
    required this.id,
    required this.itemKind,
    required this.itemId,
    required this.label,
    required this.skillScore,
    required this.nextReviewAt,
    required this.isDue,
    required this.totalCorrect,
    required this.totalIncorrect,
  });

  final String id;
  final String itemKind;
  final String itemId;
  final String? label;
  final int skillScore;
  final DateTime nextReviewAt;
  final bool isDue;
  final int totalCorrect;
  final int totalIncorrect;

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    return ProgressItem(
      id: json['id'] as String,
      itemKind: json['itemKind'] as String? ?? 'word',
      itemId: json['itemId'] as String,
      label: json['label'] as String?,
      skillScore: json['skillScore'] as int? ?? 0,
      nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
      isDue: json['isDue'] as bool? ?? false,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalIncorrect: json['totalIncorrect'] as int? ?? 0,
    );
  }
}

class ProgressSummary {
  ProgressSummary({
    required this.totalTracked,
    required this.dueCount,
    required this.averageSkillScore,
    required this.items,
  });

  final int totalTracked;
  final int dueCount;
  final int averageSkillScore;
  final List<ProgressItem> items;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalTracked: json['totalTracked'] as int? ?? 0,
      dueCount: json['dueCount'] as int? ?? 0,
      averageSkillScore: json['averageSkillScore'] as int? ?? 0,
      items: (json['items'] as List? ?? [])
          .map((e) => ProgressItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ReviewsQueue {
  ReviewsQueue({required this.count, required this.items});

  final int count;
  final List<ProgressItem> items;

  factory ReviewsQueue.fromJson(Map<String, dynamic> json) {
    return ReviewsQueue(
      count: json['count'] as int? ?? 0,
      items: (json['items'] as List? ?? [])
          .map((e) => ProgressItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ProgressRepository {
  ProgressRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ProgressSummary> getProgress() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/progress');
      return ProgressSummary.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ReviewsQueue> getReviews({int limit = 50}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/reviews',
        queryParameters: {'limit': limit},
      );
      return ReviewsQueue.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
