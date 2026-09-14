import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class ReengagementStatus {
  ReengagementStatus({
    required this.requiresDiagnostic,
    this.lastSeenAt,
    this.diagnosticCompletedAt,
    this.diagnosticLessonId,
    this.diagnosticLessonTitle,
    this.absenceThresholdDays = 3,
  });

  final bool requiresDiagnostic;
  final DateTime? lastSeenAt;
  final DateTime? diagnosticCompletedAt;
  final String? diagnosticLessonId;
  final String? diagnosticLessonTitle;
  final int absenceThresholdDays;

  factory ReengagementStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) =>
        raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);

    return ReengagementStatus(
      requiresDiagnostic: json['requiresDiagnostic'] as bool? ?? false,
      lastSeenAt: parse(json['lastSeenAt'] as String?),
      diagnosticCompletedAt: parse(json['diagnosticCompletedAt'] as String?),
      diagnosticLessonId: json['diagnosticLessonId'] as String?,
      diagnosticLessonTitle: json['diagnosticLessonTitle'] as String?,
      absenceThresholdDays: json['absenceThresholdDays'] as int? ?? 3,
    );
  }
}

class ReengagementRepository {
  ReengagementRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ReengagementStatus> getStatus() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/reengagement/status',
      );
      return ReengagementStatus.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
