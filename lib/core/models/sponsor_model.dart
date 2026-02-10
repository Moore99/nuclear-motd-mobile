import 'package:json_annotation/json_annotation.dart';

part 'sponsor_model.g.dart';

/// Sponsor model for displaying ads/sponsors in the app
@JsonSerializable()
class SponsorModel {
  final int id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  final String? tagline;
  final String? description;
  final String tier; // bronze, silver, gold, platinum
  @JsonKey(name: 'is_active')
  final bool isActive;

  SponsorModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.websiteUrl,
    this.tagline,
    this.description,
    required this.tier,
    this.isActive = true,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) =>
      _$SponsorModelFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorModelToJson(this);
}

/// Message sponsorship - sponsor banner on specific messages
@JsonSerializable()
class MessageSponsorshipModel {
  final int id;
  @JsonKey(name: 'message_id')
  final int messageId;
  @JsonKey(name: 'sponsor_id')
  final int sponsorId;
  final SponsorModel? sponsor;
  @JsonKey(name: 'display_type')
  final String displayType; // banner, footer, sidebar
  final String position; // top, bottom, inline
  @JsonKey(name: 'custom_message')
  final String? customMessage;

  MessageSponsorshipModel({
    required this.id,
    required this.messageId,
    required this.sponsorId,
    this.sponsor,
    this.displayType = 'banner',
    this.position = 'bottom',
    this.customMessage,
  });

  factory MessageSponsorshipModel.fromJson(Map<String, dynamic> json) =>
      _$MessageSponsorshipModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageSponsorshipModelToJson(this);
}

/// Topic sponsorship - sponsor for entire topics
@JsonSerializable()
class TopicSponsorshipModel {
  final int id;
  @JsonKey(name: 'topic_id')
  final int topicId;
  @JsonKey(name: 'sponsor_id')
  final int sponsorId;
  final SponsorModel? sponsor;
  @JsonKey(name: 'is_active')
  final bool isActive;

  TopicSponsorshipModel({
    required this.id,
    required this.topicId,
    required this.sponsorId,
    this.sponsor,
    this.isActive = true,
  });

  factory TopicSponsorshipModel.fromJson(Map<String, dynamic> json) =>
      _$TopicSponsorshipModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopicSponsorshipModelToJson(this);
}
