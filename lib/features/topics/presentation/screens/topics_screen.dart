import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../shared/widgets/overflow_menu.dart';

/// Topics provider
final topicsProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(AppConfig.topics);
  return response.data;
});

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  Set<String> _selectedTopics = {};
  bool _hasChanges = false;
  bool _isSaving = false;

  Future<void> _saveTopics() async {
    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        AppConfig.topicsSubscribe,
        data: _selectedTopics.toList(),
      );

      setState(() => _hasChanges = false);
      ref.refresh(topicsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topic preferences saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.friendlyMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Topics'),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveTopics,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          const OverflowMenu(),
        ],
      ),
      body: topicsAsync.when(
        data: (data) => _buildTopicsList(data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error),
      ),
    );
  }

  Widget _buildTopicsList(Map<String, dynamic> data) {
    final topics = data['topics'] as List? ?? [];
    final totalTopics = data['total_topics'] ?? topics.length;

    // Initialize selected topics from server data on first load
    if (!_hasChanges) {
      final serverSelected = topics
          .where((t) => t['subscribed'] == true)
          .map<String>((t) => t['name'] as String)
          .toSet();
      if (_selectedTopics.isEmpty || _selectedTopics != serverSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedTopics = serverSelected;
            });
          }
        });
      }
    }

    return Column(
      children: [
        // Header - wrapped in flexible container to prevent overflow
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.primary.withValues(alpha:0.05),
          child: Row(
            children: [
              Icon(Icons.category, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select topics to receive relevant messages',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_selectedTopics.length}/$totalTopics',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Topics list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final name = topic['name'] as String;
              final description = topic['description'] as String?;
              final isSelected = _selectedTopics.contains(name);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedTopics.add(name);
                      } else {
                        _selectedTopics.remove(name);
                      }
                      _hasChanges = true;
                    });
                  },
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: description != null
                      ? Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  activeColor: AppColors.primary,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            },
          ),
        ),

        // Quick actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTopics.clear();
                        _hasChanges = true;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final allTopics = (topics as List)
                          .map<String>((t) => t['name'] as String)
                          .toSet();
                      setState(() {
                        _selectedTopics = allTopics;
                        _hasChanges = true;
                      });
                    },
                    child: const Text('Select All'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
    String message = 'Failed to load topics';
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
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(topicsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
