enum PathNodeStatus { locked, active, completed }

/// A clickable node on the zigzag learning path.
class PathNodeModel {
  final String id;
  final String title;
  final String subtitle;
  final int order;
  final PathNodeStatus status;

  const PathNodeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.status,
  });
}
