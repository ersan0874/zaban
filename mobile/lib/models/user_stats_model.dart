class UserStatsModel {
  final String id;
  final String userId;
  final int hearts;
  final int gems;
  final int streak;
  final DateTime? lastActivityDate;
  final bool hasActiveSubscription;
  final bool infiniteHearts;
  final bool? heartDeducted;

  const UserStatsModel({
    required this.id,
    required this.userId,
    required this.hearts,
    required this.gems,
    required this.streak,
    this.lastActivityDate,
    this.hasActiveSubscription = false,
    this.infiniteHearts = false,
    this.heartDeducted,
  });

  static const int maxHearts = 5;
  static const int refillCost = 50;

  bool get isOutOfHearts => !infiniteHearts && hearts <= 0;
  bool get heartsFull => hearts >= maxHearts;
  bool get canAffordRefill => gems >= refillCost;
  bool get isSuper => hasActiveSubscription || infiniteHearts;

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    DateTime? lastActivity;
    final raw = json['lastActivityDate'];
    if (raw is String && raw.isNotEmpty) {
      lastActivity = DateTime.tryParse(raw);
    }

    return UserStatsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      hearts: json['hearts'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastActivityDate: lastActivity,
      hasActiveSubscription: json['hasActiveSubscription'] as bool? ?? false,
      infiniteHearts: json['infiniteHearts'] as bool? ?? false,
      heartDeducted: json['heartDeducted'] as bool?,
    );
  }
}
