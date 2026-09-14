import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class CourseMastery {
  CourseMastery({required this.courseId, required this.score});

  final String courseId;
  final double score;

  factory CourseMastery.fromJson(Map<String, dynamic> json) {
    final raw = json['score'];
    final score = raw is num ? raw.toDouble() : 0.0;
    return CourseMastery(
      courseId: json['courseId'] as String? ?? '',
      score: score,
    );
  }
}

class MasteryRepository {
  MasteryRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<CourseMastery> getCourseMastery(String courseId) async {
    try {
      final res = await _client.dio
          .get<Map<String, dynamic>>('/mastery/courses/$courseId');
      return CourseMastery.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
