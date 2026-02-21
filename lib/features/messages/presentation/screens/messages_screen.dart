import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/share_service.dart';
import '../../../shared/widgets/overflow_menu.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/bell_icon.dart';
import '../../messages_provider.dart';

/// Check if we're on a mobile platform that supports ads
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}


class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  NativeAd? _nativeAd;
  bool _isNativeAdReady = false;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    if (_isMobilePlatform) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    if (!_isMobilePlatform) return;

    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid
          ? AppConfig.nativeAdUnitIdAndroid
          : AppConfig.nativeAdUnitIdIOS,
      factoryId: 'listTile', // You'll need to set up native ad factory
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isNativeAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Messages'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showUnreadOnly ? Icons.mark_email_unread : Icons.mark_email_unread_outlined),
            onPressed: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
            tooltip: _showUnreadOnly ? 'Show all messages' : 'Show unread only',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(messagesProvider.notifier).loadMessages(),
          ),
          const OverflowMenu(),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List messages) {
    // Apply unread filter if active (client-side; no extra API call)
    final displayMessages = _showUnreadOnly
        ? messages.where((m) => m['read_in_app'] == false).toList()
        : messages;

    if (displayMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_showUnreadOnly ? Icons.message_outlined : Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _showUnreadOnly ? 'No unread messages' : 'No messages available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Insert native ad after every 5 items
    final itemsWithAds = <dynamic>[];
    for (var i = 0; i < displayMessages.length; i++) {
      itemsWithAds.add(displayMessages[i]);
      // Insert ad placeholder after every 5 items (but not after the last)
      if ((i + 1) % 5 == 0 && i < displayMessages.length - 1) {
        itemsWithAds.add('ad');
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(messagesProvider.notifier).loadMessages();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemsWithAds.length,
        itemBuilder: (context, index) {

          final item = itemsWithAds[index];

          // Native ad
          if (item == 'ad') {
            if (_isNativeAdReady && _nativeAd != null) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 72,
                child: AdWidget(ad: _nativeAd!),
              );
            }
            return const SizedBox.shrink();
          }

          // Message item
          return _MessageCard(message: item);
        },
      ),
    );
  }

  Widget _buildError(Object error) {
    String message = 'Failed to load messages';
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
              onPressed: () =>
                  ref.read(messagesProvider.notifier).loadMessages(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageCard({required this.message});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Get a color based on topic name for visual variety
  Color _getTopicColor(String topic) {
    final colors = [
      const Color(0xFF3B82F6), // blue
      const Color(0xFF10B981), // green
      const Color(0xFFF59E0B), // amber
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFEF4444), // red
      const Color(0xFF06B6D4), // cyan
      const Color(0xFFEC4899), // pink
      const Color(0xFF6366F1), // indigo
    ];
    return colors[topic.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isRead = message['read_in_app'] == true;
    final readStatus = isRead ? 'read' : 'unread';
    final statusColor = isRead ? Colors.grey : AppColors.primary;
    final topics = message['topics'] as List? ?? [];

    return Card(
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
              // Topics row at top (like web version)
              if (topics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: topics.map<Widget>((topic) {
                      final color = _getTopicColor(topic.toString());
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha:0.3)),
                        ),
                        child: Text(
                          topic.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Title
              Text(
                message['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Content preview
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Bottom row with date, status, and share
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(message['sent_at'] ?? message['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  // Share button
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      ShareService.shareMessage(
                        title: message['title'] ?? 'Nuclear MOTD Message',
                        content: message['content'] ?? '',
                      );
                    },
                    tooltip: 'Share',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          readStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
