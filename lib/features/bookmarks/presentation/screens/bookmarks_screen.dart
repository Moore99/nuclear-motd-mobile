import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/message_cache_service.dart';
import '../../../../core/services/bookmarks_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

/// Provider for bookmarked messages data
final bookmarkedMessagesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final bookmarkIds = ref.watch(bookmarksProvider);
  final cachedMessages = MessageCacheService.getCachedMessages();
  
  // Filter cached messages to only include bookmarked ones
  // Maintain bookmark order (most recently bookmarked first)
  final bookmarkIdList = bookmarkIds.toList();
  final bookmarked = <Map<String, dynamic>>[];
  
  for (final id in bookmarkIdList) {
    final message = cachedMessages.firstWhere(
      (m) => m['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (message.isNotEmpty) {
      bookmarked.add(message);
    }
  }
  
  return bookmarked;
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedMessages = ref.watch(bookmarkedMessagesProvider);
    final bookmarkIds = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Bookmarks'),
          ],
        ),
        actions: [
          if (bookmarkIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context, ref),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: bookmarkedMessages.isEmpty
          ? _buildEmptyState()
          : _buildBookmarksList(bookmarkedMessages, ref),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any message\nto save it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<Map<String, dynamic>> messages, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _BookmarkCard(
          message: message,
          onRemove: () {
            ref.read(bookmarksProvider.notifier).toggle(message['id'] as int);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bookmark removed'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all bookmarks?'),
        content: const Text('This will remove all saved bookmarks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await BookmarksService.clearAll();
              ref.read(bookmarksProvider.notifier).refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All bookmarks cleared'),
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onRemove;

  const _BookmarkCard({required this.message, required this.onRemove});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = message['title'] as String? ?? 'Untitled';
    final content = message['content'] as String? ?? '';
    final topics = message['topics'] as List? ?? [];

    return Dismissible(
      key: Key('bookmark_${message['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: () {
            final id = message['id'];
            context.push('/messages/$id');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topics
                if (topics.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: topics.map<Widget>((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            topic.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // Title row with bookmark icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark,
                        color: AppColors.primary,
                      ),
                      onPressed: onRemove,
                      tooltip: 'Remove bookmark',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Content preview
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Date
                Text(
                  _formatDate(message['created_at'] as String?),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
