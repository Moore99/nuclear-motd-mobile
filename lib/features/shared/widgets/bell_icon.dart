import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';

/// Unread message count — auto-refreshes on login/logout, can be manually
/// invalidated (e.g. after marking a message as read).
final unreadCountProvider = FutureProvider<int>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return 0;
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(AppConfig.unreadCount);
    return (response.data['unread_count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

/// Bell icon for the AppBar showing the live unread message count.
/// Tapping navigates to the Messages screen.
class BellIcon extends ConsumerWidget {
  const BellIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: count > 0 ? '$count unread' : 'Messages',
      onPressed: () => context.go(AppRoutes.messages),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(count > 0 ? Icons.notifications : Icons.notifications_none),
          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
