import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import 'change_password_screen.dart';

/// Profile provider
final profileProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(AppConfig.profile);
  return response.data;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isSaving = false;
  
  // Biometrics
  final _localAuth = LocalAuthentication();
  bool _canUseBiometrics = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadBiometricPreference();
  }

  bool get _supportsBiometrics {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _checkBiometrics() async {
    if (!_supportsBiometrics) return;
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canUseBiometrics = canAuthenticate && isDeviceSupported;
      });
    } catch (e) {
      debugPrint('Biometrics check error: $e');
    }
  }

  Future<void> _loadBiometricPreference() async {
    final storage = ref.read(secureStorageProvider);
    final savedEmail = await storage.read(key: 'saved_email');
    final savedPassword = await storage.read(key: 'saved_password');
    setState(() {
      _biometricsEnabled = savedEmail != null && savedPassword != null;
    });
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (enabled) {
      // Need to verify with biometrics first
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to enable biometric login',
          persistAcrossBackgrounding: true,
        );
        
        if (authenticated) {
          // Show dialog to enter password to save
          if (mounted) {
            final password = await _showPasswordDialog();
            if (password != null && password.isNotEmpty) {
              final storage = ref.read(secureStorageProvider);
              final profile = ref.read(profileProvider).valueOrNull;
              final email = profile?['profile']?['email'];
              
              if (email != null) {
                await storage.write(key: 'saved_email', value: email);
                await storage.write(key: 'saved_password', value: password);
                setState(() => _biometricsEnabled = true);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric login enabled'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Biometric setup error: $e');
      }
    } else {
      // Disable biometrics
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'saved_email');
      await storage.delete(key: 'saved_password');
      setState(() => _biometricsEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled'),
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to enable biometric login.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        AppConfig.profile,
        data: {
          'name': _nameController.text.trim(),
          'company': _companyController.text.trim(),
          'country': _countryController.text.trim(),
        },
      );

      setState(() => _isEditing = false);
      ref.refresh(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear token and saved credentials on explicit logout
      await clearAuthToken(ref);
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'saved_email');
      await storage.delete(key: 'saved_password');

      // Navigate to login
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Profile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push(AppRoutes.help),
            tooltip: 'Help',
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                final profile = profileAsync.valueOrNull?['profile'];
                if (profile != null) {
                  _nameController.text = profile['name'] ?? '';
                  _companyController.text = profile['company'] ?? '';
                  _countryController.text = profile['country'] ?? '';
                  setState(() => _isEditing = true);
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (data) => _buildProfile(data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error, stack),
      ),
    );
  }

  Widget _buildProfile(Map<String, dynamic> data) {
    final profile = data['profile'] ?? {};
    
    // Safely get content_topics as a List
    List<dynamic> topicsList = [];
    final topics = profile['content_topics'];
    if (topics is List) {
      topicsList = topics;
    }

    if (_isEditing) {
      return _buildEditForm(profile);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (profile['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile['name'] ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile['email'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Account details
          _buildSection('Account Details', [
            _buildDetailRow(Icons.mail_outline, 'Email', profile['email'] ?? 'N/A'),
            _buildDetailRow(Icons.business_outlined, 'Company', profile['company'] ?? 'Not set'),
            _buildDetailRow(Icons.location_on_outlined, 'Country', profile['country'] ?? 'Not set'),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Member Since',
              _formatDate(profile['created_at']),
            ),
          ]),
          const SizedBox(height: 24),

          // Email Schedule
          _buildSection('Email Schedule', [
            _buildDetailRow(
              Icons.schedule_outlined, 
              'Frequency', 
              _formatFrequency(profile['email_frequency']),
            ),
            _buildDetailRow(
              Icons.access_time_outlined,
              'Delivery Time',
              '${profile['preferred_send_hour'] ?? 10}:00 ${profile['timezone'] ?? 'UTC'}',
            ),
            if (profile['email_frequency'] == 'custom' || profile['selected_days'] != null)
              _buildDetailRow(
                Icons.date_range_outlined,
                'Days',
                _formatSelectedDays(profile['selected_days']),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await context.push(AppRoutes.schedule);
                  if (result == true) {
                    ref.refresh(profileProvider);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Schedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Subscribed topics
          _buildSection('Subscribed Topics', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topicsList.take(10).map<Widget>((topic) => Chip(
                    label: Text(topic.toString()),
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  )).toList(),
            ),
            if (topicsList.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${topicsList.length - 10} more topics',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            if (topicsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No topics subscribed',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.topics),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Manage Topics'),
            ),
          ]),
          const SizedBox(height: 24),

          // Security section
          _buildSection('Security', [
            // Change Password
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            // Biometric login (only on mobile)
            if (_supportsBiometrics && _canUseBiometrics)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.fingerprint, color: Colors.grey.shade600),
                title: const Text('Biometric Login'),
                subtitle: const Text('Use fingerprint or face to sign in'),
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
                activeColor: AppColors.primary,
              ),
          ]),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 32),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Nuclear MOTD v${AppConfig.appVersion}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.about),
                  child: Text(
                    'About this app',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} Kernkraft Consulting Inc.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(Map<String, dynamic> profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error, StackTrace? stack) {
    String message = 'Failed to load profile';
    if (error is DioException) {
      message = error.friendlyMessage;
    } else {
      message = error.toString();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message, 
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatFrequency(String? frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'custom':
        return 'Custom Schedule';
      case 'disabled':
        return 'Disabled';
      default:
        return 'Daily';
    }
  }

  String _formatSelectedDays(dynamic days) {
    if (days == null) return 'Weekdays';
    
    List<int> daysList = [];
    if (days is List) {
      daysList = days.map((d) => d as int).toList();
    } else if (days is String) {
      daysList = days.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList();
    }
    
    if (daysList.isEmpty) return 'Not set';
    
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedNames = daysList.where((d) => d >= 0 && d <= 6).map((d) => dayNames[d]).toList();
    
    if (selectedNames.length == 7) return 'Every day';
    if (selectedNames.length == 5 && !daysList.contains(0) && !daysList.contains(6)) {
      return 'Weekdays';
    }
    
    return selectedNames.join(', ');
  }
}
