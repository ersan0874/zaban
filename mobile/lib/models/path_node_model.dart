enum PathNodeStatus { locked, active, completed }

/// A clickable node on the zigzag learning path.
class PathNodeModel {
  final String id;
  final String title;
  final String subtitle;
  final int order;
  final PathNodeStatus status;
  final int lessonCount;

  const PathNodeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.status,
    this.lessonCount = 0,
  });

  factory PathNodeModel.fromApi(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'locked';
    final status = switch (statusRaw) {
      'active' => PathNodeStatus.active,
      'completed' => PathNodeStatus.completed,
      _ => PathNodeStatus.locked,
    };
    final lessonCount = json['lessonCount'] as int? ?? 0;
    return PathNodeModel(
      id: json['unitId'] as String,
      title: json['title'] as String? ?? 'یونیت',
      subtitle: json['sectionTitle'] as String? ??
          (lessonCount > 0 ? '$lessonCount درس' : 'یونیت'),
      order: json['order'] as int? ?? 0,
      status: status,
      lessonCount: lessonCount,
    );
  }
}
