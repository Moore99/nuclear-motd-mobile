import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String? name;
  final String email;
  final String? company;
  final String? country;
  @JsonKey(name: 'content_topics')
  final List<String>? contentTopics;
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'last_login')
  final String? lastLogin;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.company,
    this.country,
    this.contentTopics,
    this.isAdmin = false,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'user_id')
  final int? userId;
  final String? name;
  final String? email;
  final String? message;

  AuthResponse({
    required this.success,
    this.accessToken,
    this.userId,
    this.name,
    this.email,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class ProfileResponse {
  final bool success;
  final UserModel? profile;
  @JsonKey(name: 'available_topics')
  final List<UserTopicModel>? availableTopics;

  ProfileResponse({
    required this.success,
    this.profile,
    this.availableTopics,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}

@JsonSerializable()
class UserTopicModel {
  final int id;
  final String name;
  final String? description;
  final bool? subscribed;

  UserTopicModel({
    required this.id,
    required this.name,
    this.description,
    this.subscribed,
  });

  factory UserTopicModel.fromJson(Map<String, dynamic> json) =>
      _$UserTopicModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserTopicModelToJson(this);
}

@JsonSerializable()
class UserTopicsResponse {
  final bool success;
  final List<UserTopicModel> topics;
  @JsonKey(name: 'user_subscribed_count')
  final int userSubscribedCount;
  @JsonKey(name: 'total_topics')
  final int totalTopics;

  UserTopicsResponse({
    required this.success,
    required this.topics,
    required this.userSubscribedCount,
    required this.totalTopics,
  });

  factory UserTopicsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserTopicsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserTopicsResponseToJson(this);
}
