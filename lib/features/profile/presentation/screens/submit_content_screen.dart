import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../shared/widgets/overflow_menu.dart';

class SubmitContentScreen extends ConsumerStatefulWidget {
  const SubmitContentScreen({super.key});

  @override
  ConsumerState<SubmitContentScreen> createState() => _SubmitContentScreenState();
}

class _SubmitContentScreenState extends ConsumerState<SubmitContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _citationTextController = TextEditingController();
  final _citationUrlController = TextEditingController();
  
  String? _selectedTopic;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _isLoadingTopics = true;
  List<Map<String, dynamic>> _topics = [];
  String? _topicsError;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(AppConfig.topics);
      final data = response.data as Map<String, dynamic>;
      
      if (!mounted) return;
      
      setState(() {
        _topics = (data['topics'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoadingTopics = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _topicsError = 'Failed to load topics';
        _isLoadingTopics = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _citationTextController.dispose();
    _citationUrlController.dispose();
    super.dispose();
  }

  void _submitContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a topic'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      debugPrint('📱 Submitting content to: ${AppConfig.apiBaseUrl}${AppConfig.contentSubmit}');
      debugPrint('📱 Topic: $_selectedTopic');
      debugPrint('📱 Title: ${_titleController.text.trim()}');
      
      final response = await dio.post(
        AppConfig.contentSubmit,
        data: {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'topic': _selectedTopic,
          'citation_text': _citationTextController.text.trim().isNotEmpty 
              ? _citationTextController.text.trim() 
              : null,
          'citation_url': _citationUrlController.text.trim().isNotEmpty 
              ? _citationUrlController.text.trim() 
              : null,
        },
      );

      debugPrint('📱 Submit response: ${response.data}');
      
      if (!mounted) return;
      
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Content submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
    } on DioException catch (e) {
      debugPrint('📱 Submit error: ${e.message}');
      debugPrint('📱 Submit error response: ${e.response?.data}');
      
      if (!mounted) return;
      
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.friendlyMessage),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      debugPrint('📱 Submit unexpected error: $e');
      
      if (!mounted) return;
      
      setState(() => _isSubmitting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _citationTextController.clear();
    _citationUrlController.clear();
    setState(() {
      _selectedTopic = null;
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Submit Content'),
          ],
        ),
        actions: const [
          OverflowMenu(),
        ],
      ),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Content Submitted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your contribution! Your content has been submitted for review and will be published once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Submit Another'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Go Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_note_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share Your Knowledge',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contribute safety insights and best practices to help the nuclear community.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Topic Selection
            const Text(
              'Topic *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingTopics
                ? const Center(child: CircularProgressIndicator())
                : _topicsError != null
                    ? Text(_topicsError!, style: const TextStyle(color: AppColors.error))
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedTopic,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select a topic',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category_outlined),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: _topics.map((topic) {
                          return DropdownMenuItem<String>(
                            value: topic['name'] as String,
                            child: Text(
                              topic['name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTopic = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a topic';
                          }
                          return null;
                        },
                      ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Title *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter a descriptive title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title_outlined),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 10) {
                  return 'Title should be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Content
            const Text(
              'Content *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Share your safety insight, best practice, or lesson learned...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 5000,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter content';
                }
                if (value.length < 50) {
                  return 'Content should be at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Citation Section (Optional)
            ExpansionTile(
              title: const Text(
                'Add Citation (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              leading: const Icon(Icons.link_outlined),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _citationTextController,
                        decoration: InputDecoration(
                          labelText: 'Citation Text',
                          hintText: 'e.g., IAEA Safety Standards Series No. SSR-2/1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _citationUrlController,
                        decoration: InputDecoration(
                          labelText: 'Citation URL',
                          hintText: 'https://...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit for Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submissions are reviewed before publication. You\'ll receive notification when approved.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
