import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class GamificationSnapshot {
  GamificationSnapshot({
    required this.xp,
    required this.streakCount,
    required this.streakFreezeCount,
    required this.hearts,
    required this.heartsCap,
    required this.lessonsCompleted,
    required this.clubUnlocked,
    required this.questPoints,
    required this.quests,
    required this.badges,
    required this.unopenedLootCount,
    required this.lootBoxes,
  });

  final int xp;
  final int streakCount;
  final int streakFreezeCount;
  final int hearts;
  final int heartsCap;
  final int lessonsCompleted;
  final bool clubUnlocked;
  final int questPoints;
  final List<DailyQuestItem> quests;
  final List<BadgeItem> badges;
  final int unopenedLootCount;
  final List<LootBoxItem> lootBoxes;

  factory GamificationSnapshot.fromJson(Map<String, dynamic> json) {
    return GamificationSnapshot(
      xp: json['xp'] as int? ?? 0,
      streakCount: json['streakCount'] as int? ?? 0,
      streakFreezeCount: json['streakFreezeCount'] as int? ?? 0,
      hearts: json['hearts'] as int? ?? 0,
      heartsCap: json['heartsCap'] as int? ?? 5,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      clubUnlocked: json['clubUnlocked'] as bool? ?? false,
      questPoints: json['questPoints'] as int? ?? 0,
      quests: (json['quests'] as List? ?? [])
          .map((e) => DailyQuestItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      badges: (json['badges'] as List? ?? [])
          .map((e) => BadgeItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unopenedLootCount: json['unopenedLootCount'] as int? ?? 0,
      lootBoxes: (json['lootBoxes'] as List? ?? [])
          .map((e) => LootBoxItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class DailyQuestItem {
  DailyQuestItem({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    required this.completed,
  });

  final String id;
  final String title;
  final int progress;
  final int target;
  final bool completed;

  factory DailyQuestItem.fromJson(Map<String, dynamic> json) {
    return DailyQuestItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class BadgeItem {
  BadgeItem({
    required this.badgeKey,
    required this.title,
    required this.pinned,
  });

  final String badgeKey;
  final String title;
  final bool pinned;

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      badgeKey: json['badgeKey'] as String,
      title: json['title'] as String? ?? '',
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

class LootBoxItem {
  LootBoxItem({required this.id, required this.opened});

  final String id;
  final bool opened;

  factory LootBoxItem.fromJson(Map<String, dynamic> json) {
    return LootBoxItem(
      id: json['id'] as String,
      opened: json['opened'] as bool? ?? false,
    );
  }
}

class GamificationRepository {
  GamificationRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<GamificationSnapshot> getSnapshot() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/gamification');
      return GamificationSnapshot.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> openLoot(String lootId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/gamification/loot/$lootId/open',
      );
      return res.data ?? {};
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> pinBadge(String badgeKey, {required bool pinned}) async {
    try {
      await _client.dio.patch(
        '/gamification/badges/$badgeKey/pin',
        data: {'pinned': pinned},
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
