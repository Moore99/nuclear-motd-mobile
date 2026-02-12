import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../../core/cache/message_cache_service.dart';

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results provider
final searchResultsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.trim().isEmpty) {
    return [];
  }
  
  final dio = ref.watch(dioProvider);
  final isOnline = ref.watch(isOnlineProvider);
  
  if (isOnline) {
    try {
      final response = await dio.get(
        AppConfig.messagesSearch,
        queryParameters: {'q': query, 'limit': 20},
      );
      return response.data as List? ?? [];
    } catch (e) {
      // Fall back to local search
      return _searchLocalMessages(query);
    }
  } else {
    // Offline: search cached messages
    return _searchLocalMessages(query);
  }
});

/// Search cached messages locally
List<Map<String, dynamic>> _searchLocalMessages(String query) {
  final cached = MessageCacheService.getCachedMessages();
  final queryLower = query.toLowerCase();
  
  return cached.where((msg) {
    final title = (msg['title'] as String? ?? '').toLowerCase();
    final content = (msg['content'] as String? ?? '').toLowerCase();
    final topics = (msg['topics'] as List? ?? []).map((t) => t.toString().toLowerCase()).toList();
    
    return title.contains(queryLower) ||
           content.contains(queryLower) ||
           topics.any((t) => t.contains(queryLower));
  }).toList();
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Debounce search to avoid too many requests
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: query.isEmpty
          ? _buildEmptyState()
          : searchResults.when(
              data: (results) => _buildResults(results, query),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for messages',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by title, content, or topic',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List results, String query) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index] as Map<String, dynamic>;
        return _SearchResultCard(message: message, query: query);
      },
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(searchResultsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final String query;

  const _SearchResultCard({required this.message, required this.query});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Highlight matching text
  TextSpan _highlightText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    
    int start = 0;
    int index = textLower.indexOf(queryLower);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.shade200,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = textLower.indexOf(queryLower, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final title = message['title'] as String? ?? 'Untitled';
    final content = message['content'] as String? ?? '';
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
              // Title with highlighting
              RichText(
                text: _highlightText(title, query).copyWith(
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Content preview with highlighting
              RichText(
                text: _highlightText(content, query).copyWith(
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
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
    );
  }
}

extension on TextSpan {
  TextSpan copyWith({TextStyle? style}) {
    return TextSpan(
      text: text,
      children: children,
      style: style ?? this.style,
    );
  }
}
