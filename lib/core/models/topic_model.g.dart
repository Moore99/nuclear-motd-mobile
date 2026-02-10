// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      messageCount: (json['message_count'] as num?)?.toInt(),
      isSubscribed: json['is_subscribed'] as bool?,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
      'message_count': instance.messageCount,
      'is_subscribed': instance.isSubscribed,
    };

TopicsResponse _$TopicsResponseFromJson(Map<String, dynamic> json) =>
    TopicsResponse(
      topics: (json['topics'] as List<dynamic>)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscribedIds: (json['subscribed_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$TopicsResponseToJson(TopicsResponse instance) =>
    <String, dynamic>{
      'topics': instance.topics,
      'subscribed_ids': instance.subscribedIds,
    };
