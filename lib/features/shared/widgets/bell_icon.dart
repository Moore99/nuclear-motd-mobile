import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../messages/messages_provider.dart';

/// Unread count derived directly from the local messages list —
/// no extra API call, updates instantly when a message is marked as read.
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(messagesProvider).valueOrNull ?? [];
  return messages.where((m) => m['read_in_app'] == false).length;
});

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
