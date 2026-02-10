import 'package:hive/hive.dart';

part 'cached_message.g.dart';

@HiveType(typeId: 0)
class CachedMessage extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String contentHtml;

  @HiveField(4)
  final List<String> topics;

  @HiveField(5)
  final String? messageType;

  @HiveField(6)
  final String? createdAt;

  @HiveField(7)
  final String? startDate;

  @HiveField(8)
  final String? endDate;

  @HiveField(9)
  final String status;

  @HiveField(10)
  final String? citationText;

  @HiveField(11)
  final String? citationUrl;

  @HiveField(12)
  final DateTime cachedAt;

  CachedMessage({
    required this.id,
    required this.title,
    required this.content,
    required this.contentHtml,
    required this.topics,
    this.messageType,
    this.createdAt,
    this.startDate,
    this.endDate,
    required this.status,
    this.citationText,
    this.citationUrl,
    required this.cachedAt,
  });

  /// Create from API response
  factory CachedMessage.fromJson(Map<String, dynamic> json) {
    return CachedMessage(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      contentHtml: json['content_html'] as String? ?? json['content'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      messageType: json['message_type'] as String?,
      createdAt: json['created_at'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: json['status'] as String? ?? 'active',
      citationText: json['citation_text'] as String?,
      citationUrl: json['citation_url'] as String?,
      cachedAt: DateTime.now(),
    );
  }

  /// Convert to map for display
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'content_html': contentHtml,
      'topics': topics,
      'message_type': messageType,
      'created_at': createdAt,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'citation_text': citationText,
      'citation_url': citationUrl,
    };
  }
}
