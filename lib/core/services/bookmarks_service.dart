import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String bookmarksBoxName = 'bookmarks';

/// Bookmarks service for local storage of favorite messages
class BookmarksService {
  static Box<int>? _bookmarksBox;

  /// Initialize bookmarks storage
  static Future<void> initialize() async {
    try {
      _bookmarksBox = await Hive.openBox<int>(bookmarksBoxName);
      debugPrint('📚 Bookmarks initialized: ${_bookmarksBox?.length ?? 0} saved');
    } catch (e) {
      debugPrint('📚 Bookmarks initialization error: $e');
    }
  }

  /// Add a message to bookmarks
  static Future<void> addBookmark(int messageId) async {
    if (_bookmarksBox == null) await initialize();
    try {
      await _bookmarksBox?.put(messageId, DateTime.now().millisecondsSinceEpoch);
      debugPrint('📚 Bookmarked message: $messageId');
    } catch (e) {
      debugPrint('📚 Add bookmark error: $e');
    }
  }

  /// Remove a message from bookmarks
  static Future<void> removeBookmark(int messageId) async {
    if (_bookmarksBox == null) await initialize();
    try {
      await _bookmarksBox?.delete(messageId);
      debugPrint('📚 Removed bookmark: $messageId');
    } catch (e) {
      debugPrint('📚 Remove bookmark error: $e');
    }
  }

  /// Toggle bookmark status
  static Future<bool> toggleBookmark(int messageId) async {
    if (isBookmarked(messageId)) {
      await removeBookmark(messageId);
      return false;
    } else {
      await addBookmark(messageId);
      return true;
    }
  }

  /// Check if a message is bookmarked
  static bool isBookmarked(int messageId) {
    return _bookmarksBox?.containsKey(messageId) ?? false;
  }

  /// Get all bookmarked message IDs (sorted by when they were bookmarked, newest first)
  static List<int> getBookmarkedIds() {
    if (_bookmarksBox == null) return [];
    
    final entries = _bookmarksBox!.toMap().entries.toList();
    // Sort by timestamp (value), newest first
    entries.sort((a, b) => (b.value).compareTo(a.value));
    return entries.map((e) => e.key as int).toList();
  }

  /// Get bookmark count
  static int get count => _bookmarksBox?.length ?? 0;

  /// Clear all bookmarks
  static Future<void> clearAll() async {
    await _bookmarksBox?.clear();
    debugPrint('📚 All bookmarks cleared');
  }
}

/// Provider for bookmarks state (triggers rebuild when bookmarks change)
final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<int>>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends StateNotifier<Set<int>> {
  BookmarksNotifier() : super({}) {
    _loadBookmarks();
  }

  void _loadBookmarks() {
    state = BookmarksService.getBookmarkedIds().toSet();
  }

  Future<void> toggle(int messageId) async {
    await BookmarksService.toggleBookmark(messageId);
    _loadBookmarks();
  }

  bool isBookmarked(int messageId) {
    return state.contains(messageId);
  }

  void refresh() {
    _loadBookmarks();
  }
}
