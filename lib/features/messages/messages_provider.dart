import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/cache/message_cache_service.dart';
import '../../core/network/dio_client.dart';

/// Fetches all messages for the current user, deduplicated and sorted
/// unread-first by the server. Client-side filtering handles unread/read views.
class MessagesNotifier extends StateNotifier<AsyncValue<List>> {
  final Ref ref;

  MessagesNotifier(this.ref) : super(const AsyncValue.loading()) {
    // If the token isn't set yet (app still initialising), wait for it before
    // loading. Covers the race where messagesProvider is created before auth
    // is restored from secure storage (seen on iOS first launch).
    ref.listen<String?>(authTokenProvider, (previous, next) {
      if (next != null && previous == null) loadMessages();
    });
    loadMessages();
  }

  Future<void> loadMessages() async {
    // Skip silently if not authenticated — the listener above will retry
    // once the token is available.
    if (ref.read(authTokenProvider) == null) return;

    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(AppConfig.messages);
      final messages = response.data as List;
      await MessageCacheService.cacheMessages(messages);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      final cached = MessageCacheService.getCachedMessages();
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Instantly marks a single message as read in local state without a
  /// network round-trip. Call this immediately after a successful mark-read
  /// API call so the UI reflects the change before the server reload completes.
  void markLocallyAsRead(int messageId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.map((m) {
      final msg = m as Map<String, dynamic>;
      if (msg['id'] == messageId) {
        return <String, dynamic>{...msg, 'read_in_app': true};
      }
      return msg;
    }).toList();
    state = AsyncValue.data(updated);
  }
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, AsyncValue<List>>((ref) {
  return MessagesNotifier(ref);
});

/// Unread count derived directly from the local messages list.
/// No API call — updates instantly when a message is marked as read.
/// Used by BellIcon (in-app) and badgeSyncProvider (home screen badge).
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(messagesProvider).valueOrNull ?? [];
  return messages.where((m) => m['read_in_app'] == false).length;
});

