import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/bookmarks_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../shared/widgets/sponsor_banner.dart';
import '../../messages_provider.dart';

/// Message detail provider
final messageDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('${AppConfig.messages}/$id');
  return response.data['message'] ?? response.data;
});

class MessageDetailScreen extends ConsumerStatefulWidget {
  final int messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  ConsumerState<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _hasMarkedAsRead = false;

  @override
  Widget build(BuildContext context) {
    final messageAsync = ref.watch(messageDetailProvider(widget.messageId));
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.contains(widget.messageId);
    
    // Mark as read when message loads (only once)
    if (!_hasMarkedAsRead && messageAsync.hasValue) {
      _hasMarkedAsRead = true;
      Future.microtask(() => _markMessageAsRead());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : null,
            ),
            onPressed: () {
              ref.read(bookmarksProvider.notifier).toggle(widget.messageId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBookmarked ? 'Bookmark removed' : 'Message bookmarked',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
          IconButton(
            key: _shareButtonKey,
            icon: const Icon(Icons.share),
            onPressed: () => _shareMessage(messageAsync),
            tooltip: 'Share',
          ),
        ],
      ),
      body: messageAsync.when(
        data: (message) => _buildMessageDetail(context, message),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error),
      ),
    );
  }

  Future<void> _markMessageAsRead() async {
    debugPrint('📱 Marking message ${widget.messageId} as read...');
    try {
      final dio = ref.read(dioProvider);
      await dio.post('${AppConfig.messages}/${widget.messageId}/mark-read');
      debugPrint('📱 Message ${widget.messageId} marked as read, refreshing badge and messages list...');
      ref.read(notificationServiceProvider).refreshBadge();
      ref.read(messagesProvider.notifier).loadMessages();
    } catch (e) {
      debugPrint('Failed to mark message as read: $e');
    }
  }

  void _shareMessage(AsyncValue<Map<String, dynamic>> messageAsync) {
    messageAsync.whenData((message) {
      final title = message['title'] as String? ?? 'Nuclear MOTD Message';
      final content = message['body_html'] as String? ?? message['content'] as String? ?? '';
      
      ShareService.shareMessage(
        title: title,
        content: content,
        sharePositionOrigin: ShareService.getSharePosition(context, _shareButtonKey),
      );
    });
  }

  Widget _buildMessageDetail(BuildContext context, Map<String, dynamic> message) {
    final citations = message['citations'] as List?;
    final citationText = message['citation_text'];
    final citationUrl = message['citation_url'];
    final topics = (message['topics'] as List?)?.cast<String>() ?? [];

    // Color palette for topic badges
    final topicColors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
    ];

    Color getTopicColor(String topic) {
      final hash = topic.hashCode.abs();
      return topicColors[hash % topicColors.length];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topics row
          if (topics.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.map((topic) {
                final color = getTopicColor(topic);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha:0.3)),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Message type badge
          if (message['message_type'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message['message_type'],
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Title
          Text(
            message['title'] ?? 'Untitled',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Date and status
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                _formatDate(message['created_at']),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message['status'] ?? 'Active',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sponsor banner
          const SponsorBanner(),
          const SizedBox(height: 24),

          // Content
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: message['body_html'] != null
                  ? Html(
                      data: message['body_html'],
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16),
                          lineHeight: LineHeight(1.6),
                        ),
                        'a': Style(
                          color: AppColors.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                      },
                      onLinkTap: (url, _, __) async {
                        if (url != null) {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                    )
                  : Text(
                      message['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Citations
          if (citations != null && citations.isNotEmpty) ...[
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...citations.map((citation) => _buildCitationCard(context, citation)),
          ] else if (citationText != null || citationUrl != null) ...[
            Text(
              'Source',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCitationCard(context, {
              'text': citationText,
              'url': citationUrl,
            }),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCitationCard(BuildContext context, Map<String, dynamic> citation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: InkWell(
        onTap: citation['url'] != null
            ? () async {
                final uri = Uri.parse(citation['url']);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.link,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  citation['text'] ?? citation['url'] ?? 'Citation',
                  style: TextStyle(
                    color: citation['url'] != null
                        ? AppColors.primary
                        : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (citation['url'] != null)
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    String message = 'Failed to load message';
    if (error is DioException) {
      message = error.friendlyMessage;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(messageDetailProvider(widget.messageId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
