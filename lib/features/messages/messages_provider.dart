import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/cache/message_cache_service.dart';
import '../../core/network/dio_client.dart';

/// Fetches all messages for the current user, deduplicated and sorted
/// unread-first by the server. Client-side filtering handles unread/read views.
class MessagesNotifier extends StateNotifier<AsyncValue<List>> {
  final Ref ref;

  MessagesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
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
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, AsyncValue<List>>((ref) {
  return MessagesNotifier(ref);
});
