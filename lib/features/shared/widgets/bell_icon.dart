import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../messages/messages_provider.dart';

// unreadCountProvider is defined in messages_provider.dart so it can be shared
// with badgeSyncProvider (home screen badge) without circular imports.

/// Bell icon for the AppBar showing the live unread message count.
/// Tapping navigates to the Messages screen.
class BellIcon extends ConsumerWidget {
  const BellIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);

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
