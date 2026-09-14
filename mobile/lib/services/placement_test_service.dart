import 'package:dio/dio.dart';
import 'package:zaban/models/placement_result_model.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/services/api_client.dart';

class PlacementTestService {
  PlacementTestService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<QuestionModel>> fetchQuestions() async {
    try {
      final response = await _api.dio.get('/placement-test/questions');
      final data = response.data;
      if (data is! List) {
        return const [];
      }

      return data
          .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'دریافت سوالات آزمون با خطا مواجه شد');
    }
  }

  Future<PlacementResultModel> submitAnswers(
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final response = await _api.dio.post(
        '/placement-test/submit',
        data: {'answers': answers},
      );
      return PlacementResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e, 'ارسال پاسخ‌ها با خطا مواجه شد');
    }
  }

  Exception _mapError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return Exception(message.join('\n'));
      }
      return Exception(message.toString());
    }
    return Exception(fallback);
  }
}
