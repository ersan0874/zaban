import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

/// An essay answer that was graded by AI after the lesson had ended.
class LateGradeNotice {
  LateGradeNotice({
    required this.attemptId,
    required this.lessonTitle,
    required this.question,
    required this.isCorrect,
    this.score,
    this.feedback,
  });

  final String attemptId;
  final String lessonTitle;
  final String question;
  final bool isCorrect;
  final double? score;
  final String? feedback;

  factory LateGradeNotice.fromJson(Map<String, dynamic> json) {
    return LateGradeNotice(
      attemptId: json['attemptId'] as String,
      lessonTitle: json['lessonTitle'] as String? ?? '',
      question: json['question'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
    );
  }
}

class LateGradesRepository {
  LateGradesRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<LateGradeNotice>> listUnseen() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/me/late-grades');
      return (res.data ?? [])
          .map(
            (e) =>
                LateGradeNotice.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> markSeen(List<String> attemptIds) async {
    try {
      await _client.dio.post<Map<String, dynamic>>(
        '/me/late-grades/seen',
        data: {'attemptIds': attemptIds},
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
