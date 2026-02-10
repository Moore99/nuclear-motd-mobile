import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../../core/cache/message_cache_service.dart';
import '../../../shared/widgets/sponsor_banner.dart';
import '../../../shared/widgets/overflow_menu.dart';
import '../../../shared/widgets/offline_banner.dart';

/// Check if we're on a mobile platform that supports ads
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Dashboard data provider with offline support
final dashboardProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(dioProvider);
  final isOnline = ref.watch(isOnlineProvider);

  debugPrint('📱 Fetching dashboard, online: $isOnline');

  try {
    final response = await dio.get(AppConfig.dashboard);
    final data = response.data as Map<String, dynamic>;

    // Cache the response
    await MessageCacheService.cacheDashboard(data);
    debugPrint('📱 Dashboard fetched and cached');

    return data;
  } catch (e) {
    debugPrint('📱 Dashboard fetch error: $e');

    // Try to return cached data
    final cached = MessageCacheService.getCachedDashboard();
    if (cached != null) {
      debugPrint('📱 Returning cached dashboard');
      return cached;
    }

    rethrow;
  }
});

/// Recent messages provider (last 3 distinct messages)
final recentMessagesProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    // Fetch extra so we have 3 distinct after dedup (same msg can appear multiple times)
    final response = await dio.get('${AppConfig.messages}?limit=10');
    final rawMessages = response.data as List;

    // Deduplicate by message_id, keep most recent sent_at
    final Map<int, Map<String, dynamic>> deduped = {};
    for (final msg in rawMessages) {
      final id = msg['id'] as int;
      final existing = deduped[id];
      if (existing == null) {
        deduped[id] = msg;
      } else {
        final existingSentAt = existing['sent_at'] as String? ?? '';
        final newSentAt = msg['sent_at'] as String? ?? '';
        if (newSentAt.compareTo(existingSentAt) > 0) {
          deduped[id] = msg;
        }
        if (existing['read_in_app'] == false || msg['read_in_app'] == false) {
          deduped[id]!['read_in_app'] = false;
        }
      }
    }
    return deduped.values.toList().take(3).toList();
  } catch (e) {
    debugPrint('📱 Recent messages fetch error: $e');
    return <dynamic>[];
  }
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isMobilePlatform) {
      _loadBannerAd();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardProvider);
      ref.invalidate(recentMessagesProvider);
    }
  }

  void _loadBannerAd() {
    if (!_isMobilePlatform) return;

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? AppConfig.bannerAdUnitIdAndroid
          : AppConfig.bannerAdUnitIdIOS,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Nuclear MOTD'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardProvider),
            tooltip: 'Refresh',
          ),
          const OverflowMenu(),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: dashboardAsync.when(
              data: (data) => _buildDashboard(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error),
            ),
          ),
          // AdMob Banner Ad (unobtrusive, at bottom)
          if (_isBannerAdReady && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final userName = data['user_name'] ?? 'User';
    final userStats = data['user_stats'] ?? {};
    final recentMessagesAsync = ref.watch(recentMessagesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(dashboardProvider);
        ref.refresh(recentMessagesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s your latest updates',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact stats chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatChip(
                      Icons.article_outlined,
                      '${userStats['messages_received'] ?? 0} received',
                      AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    _buildStatChip(
                      Icons.category_outlined,
                      '${userStats['subscribed_topics'] ?? 0}/${userStats['total_topics'] ?? 0} topics',
                      AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Messages Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Messages',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.messages),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent messages list
            recentMessagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? _buildNoMessagesCard()
                  : Column(
                      children: messages
                          .map<Widget>((msg) => _buildMessageCard(msg))
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _buildNoMessagesCard(),
            ),
            const SizedBox(height: 16),

            // Sponsor banner (your own sponsors from API)
            const SponsorBanner(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topics = message['topics'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          final id = message['id'];
          context.push('/messages/$id');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and arrow
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message['title'] ?? 'Message',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Preview text
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Topics chips + read status row
              Row(
                children: [
                  if (topics.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: topics.take(2).map<Widget>((topic) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              topic.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    const Spacer(),
                  // Read / Unread badge
                  _buildReadBadge(message),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMessagesCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your first message will appear here after it\'s sent based on your schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadBadge(Map<String, dynamic> message) {
    final isRead = message['read_in_app'] == true;
    final color = isRead ? Colors.grey.shade500 : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isRead ? 'read' : 'unread',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    String message = 'Failed to load dashboard';
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
              onPressed: () => ref.refresh(dashboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
