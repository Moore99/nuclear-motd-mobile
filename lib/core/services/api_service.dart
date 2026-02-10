import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../network/dio_client.dart';

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

/// Centralized API service for all backend calls
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // ==================== AUTH ====================

  /// Login user
  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post(
      AppConfig.authLogin,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Signup new user
  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String name,
    String? company,
    String? country,
  }) async {
    final response = await _dio.post(
      AppConfig.authSignup,
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (company != null) 'company': company,
        if (country != null) 'country': country,
      },
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Logout user
  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
  }

  // ==================== DASHBOARD ====================

  /// Get dashboard data
  Future<DashboardData> getDashboard() async {
    final response = await _dio.get(AppConfig.dashboard);
    return DashboardData.fromJson(response.data);
  }

  // ==================== MESSAGES ====================

  /// Get messages list
  Future<MessagesResponse> getMessages({
    int page = 1,
    int limit = 20,
    int? topicId,
  }) async {
    final response = await _dio.get(
      AppConfig.messages,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (topicId != null) 'topic_id': topicId,
      },
    );
    return MessagesResponse.fromJson(response.data);
  }

  /// Get message detail
  Future<MessageModel> getMessage(int id) async {
    final response = await _dio.get('${AppConfig.messages}/$id');
    return MessageModel.fromJson(response.data);
  }

  // ==================== PROFILE ====================

  /// Get user profile
  Future<UserModel> getProfile() async {
    final response = await _dio.get(AppConfig.profile);
    return UserModel.fromJson(response.data);
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? company,
  }) async {
    final response = await _dio.put(
      AppConfig.profile,
      data: {
        if (name != null) 'name': name,
        if (company != null) 'company': company,
      },
    );
    return UserModel.fromJson(response.data);
  }

  // ==================== TOPICS ====================

  /// Get all topics
  Future<TopicsResponse> getTopics() async {
    final response = await _dio.get(AppConfig.topics);
    return TopicsResponse.fromJson(response.data);
  }

  /// Subscribe to topics
  Future<void> subscribeToTopics(List<int> topicIds) async {
    await _dio.post(
      AppConfig.topicsSubscribe,
      data: {'topic_ids': topicIds},
    );
  }

  // ==================== SPONSORS ====================

  /// Get active sponsors
  Future<List<SponsorModel>> getActiveSponsors({int limit = 5}) async {
    final response = await _dio.get(
      AppConfig.sponsors,
      queryParameters: {'limit': limit},
    );
    final List<dynamic> data = response.data;
    return data.map((json) => SponsorModel.fromJson(json)).toList();
  }

  /// Track sponsor impression
  Future<void> trackSponsorImpression(int sponsorshipId, {String type = 'message'}) async {
    await _dio.get(
      '${AppConfig.sponsorImpression}/$sponsorshipId',
      queryParameters: {'sponsorship_type': type},
    );
  }

  /// Track sponsor click
  Future<void> trackSponsorClick(int sponsorshipId, String url, {String type = 'message'}) async {
    await _dio.get(
      '${AppConfig.sponsorClick}/$sponsorshipId',
      queryParameters: {
        'url': url,
        'sponsorship_type': type,
      },
    );
  }

  // ==================== APP INFO ====================

  /// Get app info (version, etc)
  Future<Map<String, dynamic>> getAppInfo() async {
    final response = await _dio.get(AppConfig.appInfo);
    return response.data;
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(AppConfig.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Get unread message count
  Future<int> getUnreadCount() async {
    final response = await _dio.get(AppConfig.unreadCount);
    return response.data['unread_count'] ?? 0;
  }
}

/// Auth response model
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'bearer',
      user: UserModel.fromJson(json['user']),
    );
  }
}

/// Dashboard data model
class DashboardData {
  final MessageModel? todayMessage;
  final int unreadCount;
  final int messageCount;
  final List<Topic> subscribedTopics;

  DashboardData({
    this.todayMessage,
    this.unreadCount = 0,
    this.messageCount = 0,
    this.subscribedTopics = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      todayMessage: json['today_message'] != null
          ? MessageModel.fromJson(json['today_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      messageCount: json['message_count'] ?? 0,
      subscribedTopics: (json['subscribed_topics'] as List<dynamic>?)
              ?.map((e) => Topic.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Messages list response
class MessagesResponse {
  final List<MessageModel> messages;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  MessagesResponse({
    required this.messages,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      hasMore: json['has_more'] ?? false,
    );
  }
}
