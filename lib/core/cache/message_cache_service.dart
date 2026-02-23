import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'cached_message.dart';

/// Box names
const String messagesBoxName = 'messages_cache';
const String dashboardBoxName = 'dashboard_cache';

/// Connectivity provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) => results.isNotEmpty && !results.contains(ConnectivityResult.none),
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error
  );
});

/// Increment this whenever CachedMessage schema changes (new HiveFields, etc.).
/// On first launch after an upgrade, old-format entries are cleared so stale
/// data (e.g. missing readInApp defaulting to false) is discarded.
const int _cacheVersion = 2;

/// Message cache service
class MessageCacheService {
  static Box<CachedMessage>? _messagesBox;
  static Box<dynamic>? _dashboardBox;

  /// Initialize Hive boxes
  static Future<void> initialize() async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedMessageAdapter());
      }

      // Open boxes
      _messagesBox = await Hive.openBox<CachedMessage>(messagesBoxName);
      _dashboardBox = await Hive.openBox(dashboardBoxName);

      // Clear messages cache if schema has been upgraded since last launch.
      // Old entries may be missing new HiveFields (e.g. readInApp added in v2)
      // and will default those fields to false, causing incorrect unread counts.
      final storedVersion = _dashboardBox!.get('cache_version') as int? ?? 1;
      if (storedVersion < _cacheVersion) {
        await _messagesBox!.clear();
        await _dashboardBox!.put('cache_version', _cacheVersion);
        debugPrint('📦 Cache cleared: schema upgrade v$storedVersion → v$_cacheVersion');
      }

      debugPrint('📦 Cache initialized (v$_cacheVersion, ${_messagesBox!.length} messages)');
    } catch (e) {
      debugPrint('📦 Cache initialization error: $e');
    }
  }

  /// Cache messages from API response
  static Future<void> cacheMessages(List<dynamic> messages) async {
    if (_messagesBox == null) return;

    try {
      // Clear old cache
      await _messagesBox!.clear();

      // Add new messages
      for (final msg in messages) {
        final cached = CachedMessage.fromJson(msg as Map<String, dynamic>);
        await _messagesBox!.put(cached.id, cached);
      }

      debugPrint('📦 Cached ${messages.length} messages');
    } catch (e) {
      debugPrint('📦 Cache messages error: $e');
    }
  }

  /// Get cached messages
  static List<Map<String, dynamic>> getCachedMessages() {
    if (_messagesBox == null) return [];

    try {
      final messages = _messagesBox!.values.toList();
      // Sort by cached date (newest first)
      messages.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
      return messages.map((m) => m.toDisplayMap()).toList();
    } catch (e) {
      debugPrint('📦 Get cached messages error: $e');
      return [];
    }
  }

  /// Cache single message detail
  static Future<void> cacheMessageDetail(Map<String, dynamic> message) async {
    if (_messagesBox == null) return;

    try {
      final cached = CachedMessage.fromJson(message);
      await _messagesBox!.put(cached.id, cached);
      debugPrint('📦 Cached message detail: ${cached.id}');
    } catch (e) {
      debugPrint('📦 Cache message detail error: $e');
    }
  }

  /// Get cached message by ID
  static Map<String, dynamic>? getCachedMessage(int id) {
    if (_messagesBox == null) return null;

    try {
      final cached = _messagesBox!.get(id);
      return cached?.toDisplayMap();
    } catch (e) {
      debugPrint('📦 Get cached message error: $e');
      return null;
    }
  }

  /// Cache dashboard data
  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    if (_dashboardBox == null) return;

    try {
      await _dashboardBox!.put('dashboard', data);
      await _dashboardBox!.put('cached_at', DateTime.now().toIso8601String());
      debugPrint('📦 Cached dashboard data');
    } catch (e) {
      debugPrint('📦 Cache dashboard error: $e');
    }
  }

  /// Get cached dashboard
  static Map<String, dynamic>? getCachedDashboard() {
    if (_dashboardBox == null) return null;

    try {
      final data = _dashboardBox!.get('dashboard');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('📦 Get cached dashboard error: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than specified duration)
  static bool isCacheStale({Duration maxAge = const Duration(hours: 24)}) {
    if (_dashboardBox == null) return true;

    try {
      final cachedAtStr = _dashboardBox!.get('cached_at') as String?;
      if (cachedAtStr == null) return true;

      final cachedAt = DateTime.parse(cachedAtStr);
      return DateTime.now().difference(cachedAt) > maxAge;
    } catch (e) {
      return true;
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    try {
      await _messagesBox?.clear();
      await _dashboardBox?.clear();
      debugPrint('📦 Cache cleared');
    } catch (e) {
      debugPrint('📦 Clear cache error: $e');
    }
  }

  /// Get cache stats
  static Map<String, dynamic> getCacheStats() {
    return {
      'messages_count': _messagesBox?.length ?? 0,
      'has_dashboard': _dashboardBox?.get('dashboard') != null,
      'cached_at': _dashboardBox?.get('cached_at'),
    };
  }
}

/// Message cache service provider
final messageCacheServiceProvider = Provider<MessageCacheService>((ref) {
  return MessageCacheService();
});
