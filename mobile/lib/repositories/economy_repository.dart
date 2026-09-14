import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class WalletSnapshot {
  WalletSnapshot({required this.gems});
  final int gems;

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    return WalletSnapshot(gems: json['gems'] as int? ?? 0);
  }
}

class ShopCatalogItem {
  ShopCatalogItem({
    required this.key,
    required this.title,
    required this.description,
    required this.priceGems,
    required this.effectType,
  });

  final String key;
  final String title;
  final String description;
  final int priceGems;
  final String effectType;

  factory ShopCatalogItem.fromJson(Map<String, dynamic> json) {
    return ShopCatalogItem(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceGems: json['priceGems'] as int? ?? 0,
      effectType: json['effectType'] as String? ?? '',
    );
  }
}

class LeagueCurrent {
  LeagueCurrent({
    required this.seasonId,
    required this.tier,
    required this.weeklyXp,
    this.weekStart,
  });

  final String seasonId;
  final String tier;
  final int weeklyXp;
  final DateTime? weekStart;

  factory LeagueCurrent.fromJson(Map<String, dynamic> json) {
    return LeagueCurrent(
      seasonId: json['seasonId'] as String? ?? '',
      tier: json['tier'] as String? ?? 'bronze',
      weeklyXp: json['weeklyXp'] as int? ?? 0,
      weekStart: json['weekStart'] != null
          ? DateTime.tryParse(json['weekStart'] as String)
          : null,
    );
  }
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.weeklyXp,
    required this.isYou,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int weeklyXp;
  final bool isYou;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Learner',
      weeklyXp: json['weeklyXp'] as int? ?? 0,
      isYou: json['isYou'] as bool? ?? false,
    );
  }
}

class LeaderboardSnapshot {
  LeaderboardSnapshot({
    required this.seasonId,
    required this.tier,
    required this.entries,
  });

  final String seasonId;
  final String tier;
  final List<LeaderboardEntry> entries;

  factory LeaderboardSnapshot.fromJson(Map<String, dynamic> json) {
    return LeaderboardSnapshot(
      seasonId: json['seasonId'] as String? ?? '',
      tier: json['tier'] as String? ?? 'bronze',
      entries: (json['entries'] as List? ?? [])
          .map(
            (e) => LeaderboardEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class EconomyRepository {
  EconomyRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<WalletSnapshot> getWallet() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/economy/wallet');
      return WalletSnapshot.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<ShopCatalogItem>> listShop() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/economy/shop');
      return (res.data ?? [])
          .map(
            (e) => ShopCatalogItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> buyShopItem(String itemKey) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/economy/shop/$itemKey/buy',
      );
      return res.data ?? {};
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LeagueCurrent> getCurrentLeague() async {
    try {
      final res =
          await _client.dio.get<Map<String, dynamic>>('/economy/leagues/current');
      return LeagueCurrent.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LeaderboardSnapshot> getLeaderboard() async {
    try {
      final res = await _client.dio
          .get<Map<String, dynamic>>('/economy/leagues/leaderboard');
      return LeaderboardSnapshot.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
