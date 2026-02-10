import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final int id;
  final String title;
  final String content;
  @JsonKey(name: 'body_html')
  final String? bodyHtml;
  @JsonKey(name: 'message_type')
  final String? messageType;
  final String? department;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'sent_at')
  final String? sentAt;
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'end_date')
  final String? endDate;
  final String status;
  final List<CitationModel>? citations;
  @JsonKey(name: 'citation_text')
  final String? citationText;
  @JsonKey(name: 'citation_url')
  final String? citationUrl;

  MessageModel({
    required this.id,
    required this.title,
    required this.content,
    this.bodyHtml,
    this.messageType,
    this.department,
    required this.createdAt,
    this.sentAt,
    this.startDate,
    this.endDate,
    required this.status,
    this.citations,
    this.citationText,
    this.citationUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// Get formatted date
  String get formattedDate {
    try {
      final dateStr = sentAt ?? createdAt;
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return sentAt ?? createdAt;
    }
  }
}

@JsonSerializable()
class CitationModel {
  final String? text;
  final String? url;

  CitationModel({this.text, this.url});

  factory CitationModel.fromJson(Map<String, dynamic> json) =>
      _$CitationModelFromJson(json);

  Map<String, dynamic> toJson() => _$CitationModelToJson(this);
}

@JsonSerializable()
class MessageDetailResponse {
  final bool success;
  final MessageModel message;

  MessageDetailResponse({
    required this.success,
    required this.message,
  });

  factory MessageDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDetailResponseToJson(this);
}

@JsonSerializable()
class DashboardResponse {
  final bool success;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'daily_message')
  final DailyMessageModel? dailyMessage;
  @JsonKey(name: 'user_stats')
  final UserStatsModel userStats;
  @JsonKey(name: 'quick_actions')
  final List<QuickActionModel> quickActions;

  DashboardResponse({
    required this.success,
    required this.userName,
    this.dailyMessage,
    required this.userStats,
    required this.quickActions,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}

@JsonSerializable()
class DailyMessageModel {
  final int id;
  final String title;
  final String content;
  @JsonKey(name: 'message_type')
  final String? messageType;
  @JsonKey(name: 'created_at')
  final String createdAt;

  DailyMessageModel({
    required this.id,
    required this.title,
    required this.content,
    this.messageType,
    required this.createdAt,
  });

  factory DailyMessageModel.fromJson(Map<String, dynamic> json) =>
      _$DailyMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyMessageModelToJson(this);
}

@JsonSerializable()
class UserStatsModel {
  @JsonKey(name: 'total_active_messages')
  final int totalActiveMessages;
  @JsonKey(name: 'subscribed_topics')
  final int subscribedTopics;
  @JsonKey(name: 'total_topics')
  final int totalTopics;
  @JsonKey(name: 'member_since')
  final String memberSince;
  @JsonKey(name: 'last_login')
  final String lastLogin;

  UserStatsModel({
    required this.totalActiveMessages,
    required this.subscribedTopics,
    required this.totalTopics,
    required this.memberSince,
    required this.lastLogin,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UserStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsModelToJson(this);
}

@JsonSerializable()
class QuickActionModel {
  final String title;
  final String action;

  QuickActionModel({
    required this.title,
    required this.action,
  });

  factory QuickActionModel.fromJson(Map<String, dynamic> json) =>
      _$QuickActionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuickActionModelToJson(this);
}
