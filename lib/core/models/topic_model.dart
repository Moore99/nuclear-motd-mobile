import 'package:json_annotation/json_annotation.dart';

part 'topic_model.g.dart';

/// Topic model for content categories
@JsonSerializable()
class Topic {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'message_count')
  final int? messageCount;
  @JsonKey(name: 'is_subscribed')
  final bool? isSubscribed;

  Topic({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.messageCount,
    this.isSubscribed,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);

  Topic copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    int? messageCount,
    bool? isSubscribed,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Response wrapper for topics list
@JsonSerializable()
class TopicsResponse {
  final List<Topic> topics;
  @JsonKey(name: 'subscribed_ids')
  final List<int>? subscribedIds;

  TopicsResponse({
    required this.topics,
    this.subscribedIds,
  });

  factory TopicsResponse.fromJson(Map<String, dynamic> json) =>
      _$TopicsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TopicsResponseToJson(this);
}
