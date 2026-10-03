import 'package:zaban/models/path_node_model.dart';

enum PathItemKind { lesson, exam, chest }

/// One stop on the learning path: a lesson, a review exam or a reward chest.
class PathItemModel {
  final String id;
  final PathItemKind kind;
  final String title;
  final PathNodeStatus status;
  final String unitId;
  final String unitTitle;

  /// Lessons: the lesson to start.
  final String? lessonId;

  /// Lessons: 1-based number on the path.
  final int number;

  /// Exams and chests: the lesson number they follow (API key).
  final int position;

  /// Exams: the lesson numbers they cover.
  final int fromNumber;
  final int toNumber;

  const PathItemModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    required this.unitId,
    required this.unitTitle,
    this.lessonId,
    this.number = 0,
    this.position = 0,
    this.fromNumber = 0,
    this.toNumber = 0,
  });

  bool get isLocked => status == PathNodeStatus.locked;
  bool get isActive => status == PathNodeStatus.active;
  bool get isCompleted => status == PathNodeStatus.completed;

  factory PathItemModel.fromApi(Map<String, dynamic> json) {
    final kind = switch (json['kind']) {
      'exam' => PathItemKind.exam,
      'chest' => PathItemKind.chest,
      _ => PathItemKind.lesson,
    };
    final status = switch (json['status']) {
      'active' => PathNodeStatus.active,
      'completed' => PathNodeStatus.completed,
      _ => PathNodeStatus.locked,
    };
    return PathItemModel(
      id: json['id'] as String? ?? '',
      kind: kind,
      title: json['title'] as String? ?? '',
      status: status,
      unitId: json['unitId'] as String? ?? '',
      unitTitle: json['unitTitle'] as String? ?? '',
      lessonId: json['lessonId'] as String?,
      number: json['number'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      fromNumber: json['fromNumber'] as int? ?? 0,
      toNumber: json['toNumber'] as int? ?? 0,
    );
  }
}

/// What a path chest gave when it was opened.
class ChestRewards {
  final int energy;
  final int gems;
  final int xp;
  final int streakFreeze;

  const ChestRewards({
    this.energy = 0,
    this.gems = 0,
    this.xp = 0,
    this.streakFreeze = 0,
  });

  factory ChestRewards.fromJson(Map<String, dynamic> json) => ChestRewards(
        energy: json['energy'] as int? ?? 0,
        gems: json['gems'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        streakFreeze: json['streakFreeze'] as int? ?? 0,
      );
}
