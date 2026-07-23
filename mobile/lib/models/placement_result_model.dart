class PlacementResultModel {
  final int score;
  final int total;
  final int percentage;
  final String level;

  const PlacementResultModel({
    required this.score,
    required this.total,
    required this.percentage,
    required this.level,
  });

  factory PlacementResultModel.fromJson(Map<String, dynamic> json) {
    return PlacementResultModel(
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
      level: json['level'] as String? ?? 'beginner',
    );
  }

  String get levelLabel {
    switch (level) {
      case 'beginner':
        return 'مبتدی';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'پیشرفته';
      default:
        return level;
    }
  }
}
