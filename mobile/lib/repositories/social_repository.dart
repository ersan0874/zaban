import 'package:dio/dio.dart';
import 'package:zaban/services/api_client.dart';

class FriendItem {
  FriendItem({
    required this.friendshipId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String friendshipId;
  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      friendshipId: json['friendshipId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'دوست',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class FriendStreak {
  FriendStreak({
    required this.userId,
    required this.displayName,
    required this.streakCount,
  });

  final String userId;
  final String displayName;
  final int streakCount;

  factory FriendStreak.fromJson(Map<String, dynamic> json) {
    return FriendStreak(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      streakCount: json['streakCount'] as int? ?? 0,
    );
  }
}

class FeedEntry {
  FeedEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.type,
    required this.message,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String type;
  final String message;
  final DateTime? createdAt;

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    return FeedEntry(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Learner',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class ChatMessageItem {
  ChatMessageItem({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    required this.isMine,
    this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String body;
  final bool isMine;
  final DateTime? createdAt;

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: json['id'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      toUserId: json['toUserId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class SocialRepository {
  SocialRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<FriendItem>> listFriends() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/social/friends');
      return (res.data ?? [])
          .map((e) => FriendItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<FriendStreak>> friendStreaks() async {
    try {
      final res =
          await _client.dio.get<Map<String, dynamic>>('/social/friends/streaks');
      final list = res.data?['friends'] as List? ?? [];
      return list
          .map(
            (e) => FriendStreak.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> requestFriend(String emailOrUserId) async {
    try {
      await _client.dio.post(
        '/social/friends/request',
        data: {'emailOrUserId': emailOrUserId},
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> acceptFriend(String friendshipId) async {
    try {
      await _client.dio.post('/social/friends/$friendshipId/accept');
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<FeedEntry>> getFeed() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/social/feed');
      return (res.data ?? [])
          .map((e) => FeedEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> postFeed(String message) async {
    try {
      await _client.dio.post('/social/feed', data: {'message': message});
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<ChatMessageItem>> getChat(String peerUserId) async {
    try {
      final res =
          await _client.dio.get<List<dynamic>>('/social/chat/$peerUserId');
      return (res.data ?? [])
          .map(
            (e) =>
                ChatMessageItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> sendChat(String peerUserId, String body) async {
    try {
      await _client.dio.post(
        '/social/chat/$peerUserId',
        data: {'body': body},
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiClient.messageFrom(e),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
