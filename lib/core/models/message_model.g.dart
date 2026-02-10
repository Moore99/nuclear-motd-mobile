// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      bodyHtml: json['body_html'] as String?,
      messageType: json['message_type'] as String?,
      department: json['department'] as String?,
      createdAt: json['created_at'] as String,
      sentAt: json['sent_at'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: json['status'] as String,
      citations: (json['citations'] as List<dynamic>?)
          ?.map((e) => CitationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      citationText: json['citation_text'] as String?,
      citationUrl: json['citation_url'] as String?,
    );

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'body_html': instance.bodyHtml,
      'message_type': instance.messageType,
      'department': instance.department,
      'created_at': instance.createdAt,
      'sent_at': instance.sentAt,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'status': instance.status,
      'citations': instance.citations,
      'citation_text': instance.citationText,
      'citation_url': instance.citationUrl,
    };

CitationModel _$CitationModelFromJson(Map<String, dynamic> json) =>
    CitationModel(
      text: json['text'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$CitationModelToJson(CitationModel instance) =>
    <String, dynamic>{
      'text': instance.text,
      'url': instance.url,
    };

MessageDetailResponse _$MessageDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MessageDetailResponse(
      success: json['success'] as bool,
      message: MessageModel.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageDetailResponseToJson(
        MessageDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    DashboardResponse(
      success: json['success'] as bool,
      userName: json['user_name'] as String,
      dailyMessage: json['daily_message'] == null
          ? null
          : DailyMessageModel.fromJson(
              json['daily_message'] as Map<String, dynamic>),
      userStats:
          UserStatsModel.fromJson(json['user_stats'] as Map<String, dynamic>),
      quickActions: (json['quick_actions'] as List<dynamic>)
          .map((e) => QuickActionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'user_name': instance.userName,
      'daily_message': instance.dailyMessage,
      'user_stats': instance.userStats,
      'quick_actions': instance.quickActions,
    };

DailyMessageModel _$DailyMessageModelFromJson(Map<String, dynamic> json) =>
    DailyMessageModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$DailyMessageModelToJson(DailyMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'message_type': instance.messageType,
      'created_at': instance.createdAt,
    };

UserStatsModel _$UserStatsModelFromJson(Map<String, dynamic> json) =>
    UserStatsModel(
      totalActiveMessages: (json['total_active_messages'] as num).toInt(),
      subscribedTopics: (json['subscribed_topics'] as num).toInt(),
      totalTopics: (json['total_topics'] as num).toInt(),
      memberSince: json['member_since'] as String,
      lastLogin: json['last_login'] as String,
    );

Map<String, dynamic> _$UserStatsModelToJson(UserStatsModel instance) =>
    <String, dynamic>{
      'total_active_messages': instance.totalActiveMessages,
      'subscribed_topics': instance.subscribedTopics,
      'total_topics': instance.totalTopics,
      'member_since': instance.memberSince,
      'last_login': instance.lastLogin,
    };

QuickActionModel _$QuickActionModelFromJson(Map<String, dynamic> json) =>
    QuickActionModel(
      title: json['title'] as String,
      action: json['action'] as String,
    );

Map<String, dynamic> _$QuickActionModelToJson(QuickActionModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'action': instance.action,
    };
