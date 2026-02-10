// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      email: json['email'] as String,
      company: json['company'] as String?,
      country: json['country'] as String?,
      contentTopics: (json['content_topics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      lastLogin: json['last_login'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'company': instance.company,
      'country': instance.country,
      'content_topics': instance.contentTopics,
      'is_admin': instance.isAdmin,
      'created_at': instance.createdAt,
      'last_login': instance.lastLogin,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      success: json['success'] as bool,
      accessToken: json['access_token'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'access_token': instance.accessToken,
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'message': instance.message,
    };

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      success: json['success'] as bool,
      profile: json['profile'] == null
          ? null
          : UserModel.fromJson(json['profile'] as Map<String, dynamic>),
      availableTopics: (json['available_topics'] as List<dynamic>?)
          ?.map((e) => UserTopicModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'profile': instance.profile,
      'available_topics': instance.availableTopics,
    };

UserTopicModel _$UserTopicModelFromJson(Map<String, dynamic> json) =>
    UserTopicModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      subscribed: json['subscribed'] as bool?,
    );

Map<String, dynamic> _$UserTopicModelToJson(UserTopicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'subscribed': instance.subscribed,
    };

UserTopicsResponse _$UserTopicsResponseFromJson(Map<String, dynamic> json) =>
    UserTopicsResponse(
      success: json['success'] as bool,
      topics: (json['topics'] as List<dynamic>)
          .map((e) => UserTopicModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      userSubscribedCount: (json['user_subscribed_count'] as num).toInt(),
      totalTopics: (json['total_topics'] as num).toInt(),
    );

Map<String, dynamic> _$UserTopicsResponseToJson(UserTopicsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'topics': instance.topics,
      'user_subscribed_count': instance.userSubscribedCount,
      'total_topics': instance.totalTopics,
    };
