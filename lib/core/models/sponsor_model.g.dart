// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SponsorModel _$SponsorModelFromJson(Map<String, dynamic> json) => SponsorModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      tier: json['tier'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$SponsorModelToJson(SponsorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl,
      'website_url': instance.websiteUrl,
      'tagline': instance.tagline,
      'description': instance.description,
      'tier': instance.tier,
      'is_active': instance.isActive,
    };

MessageSponsorshipModel _$MessageSponsorshipModelFromJson(
        Map<String, dynamic> json) =>
    MessageSponsorshipModel(
      id: (json['id'] as num).toInt(),
      messageId: (json['message_id'] as num).toInt(),
      sponsorId: (json['sponsor_id'] as num).toInt(),
      sponsor: json['sponsor'] == null
          ? null
          : SponsorModel.fromJson(json['sponsor'] as Map<String, dynamic>),
      displayType: json['display_type'] as String? ?? 'banner',
      position: json['position'] as String? ?? 'bottom',
      customMessage: json['custom_message'] as String?,
    );

Map<String, dynamic> _$MessageSponsorshipModelToJson(
        MessageSponsorshipModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_id': instance.messageId,
      'sponsor_id': instance.sponsorId,
      'sponsor': instance.sponsor,
      'display_type': instance.displayType,
      'position': instance.position,
      'custom_message': instance.customMessage,
    };

TopicSponsorshipModel _$TopicSponsorshipModelFromJson(
        Map<String, dynamic> json) =>
    TopicSponsorshipModel(
      id: (json['id'] as num).toInt(),
      topicId: (json['topic_id'] as num).toInt(),
      sponsorId: (json['sponsor_id'] as num).toInt(),
      sponsor: json['sponsor'] == null
          ? null
          : SponsorModel.fromJson(json['sponsor'] as Map<String, dynamic>),
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$TopicSponsorshipModelToJson(
        TopicSponsorshipModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topic_id': instance.topicId,
      'sponsor_id': instance.sponsorId,
      'sponsor': instance.sponsor,
      'is_active': instance.isActive,
    };
