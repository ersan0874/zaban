import 'package:dio/dio.dart';
import 'package:zaban/models/path_item_model.dart';
import 'package:zaban/models/path_node_model.dart';
import 'package:zaban/models/word_model.dart';
import 'package:zaban/services/api_client.dart';

class CourseSummary {
  CourseSummary({
    required this.id,
    required this.title,
    this.description,
  });

  final String id;
  final String title;
  final String? description;

  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    return CourseSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }
}

class UnitLessonSummary {
  UnitLessonSummary({
    required this.id,
    required this.title,
    required this.order,
    this.summary,
    this.estimatedMinutes = 4,
    this.exerciseCount = 0,
  });

  final String id;
  final String title;
  final int order;
  final String? summary;
  final int estimatedMinutes;
  final int exerciseCount;

  factory UnitLessonSummary.fromJson(Map<String, dynamic> json) {
    return UnitLessonSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
      summary: json['summary'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 4,
      exerciseCount: json['exerciseCount'] as int? ?? 0,
    );
  }
}

class UnitDetail {
  UnitDetail({
    required this.id,
    required this.title,
    required this.lessons,
    required this.words,
  });

  final String id;
  final String title;
  final List<UnitLessonSummary> lessons;
  final List<WordModel> words;

  factory UnitDetail.fromJson(Map<String, dynamic> json) {
    return UnitDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      lessons: (json['lessons'] as List? ?? [])
          .map((e) => UnitLessonSummary.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      words: (json['words'] as List? ?? [])
          .map((e) => WordModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Lessons that have exercises, in path order (AI units often have several).
  List<UnitLessonSummary> get practiceLessons =>
      lessons.where((l) => l.exerciseCount > 0).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  UnitLessonSummary? get quizLesson {
    final withExercises = lessons.where((l) => l.exerciseCount > 0).toList();
    if (withExercises.isNotEmpty) {
      withExercises.sort((a, b) => a.order.compareTo(b.order));
      return withExercises.first;
    }
    if (lessons.isEmpty) return null;
    final sorted = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
    return sorted.last;
  }
}

class CurriculumRepository {
  CurriculumRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<CourseSummary>> listCourses() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/courses');
      return (res.data ?? [])
          .map((e) =>
              CourseSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiClient.messageFrom(e),
          statusCode: e.response?.statusCode);
    }
  }

  Future<
      ({
        CourseSummary course,
        List<PathNodeModel> nodes,
        List<PathItemModel> items,
      })> getPath(
    String courseId,
  ) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/courses/$courseId/path',
      );
      final data = res.data ?? {};
      final course = CourseSummary.fromJson(
        Map<String, dynamic>.from(data['course'] as Map),
      );
      final nodes = (data['nodes'] as List? ?? [])
          .map(
              (e) => PathNodeModel.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      final items = (data['items'] as List? ?? [])
          .map(
              (e) => PathItemModel.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      return (course: course, nodes: nodes, items: items);
    } on DioException catch (e) {
      throw ApiException(ApiClient.messageFrom(e),
          statusCode: e.response?.statusCode);
    }
  }

  /// Opens the reward chest after lesson [position] of the path.
  Future<ChestRewards> openChest(String courseId, int position) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/courses/$courseId/path/chests/$position/open',
      );
      final rewards = res.data?['rewards'];
      return rewards is Map
          ? ChestRewards.fromJson(Map<String, dynamic>.from(rewards))
          : const ChestRewards();
    } on DioException catch (e) {
      throw ApiException(ApiClient.messageFrom(e),
          statusCode: e.response?.statusCode);
    }
  }

  Future<UnitDetail> getUnit(String unitId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/units/$unitId');
      return UnitDetail.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(ApiClient.messageFrom(e),
          statusCode: e.response?.statusCode);
    }
  }
}
