import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/bookmarks_service.dart';
import '../../../core/cache/message_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

/// Check if we're on a mobile platform
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Shared overflow menu for all main screens
class OverflowMenu extends ConsumerWidget {
  const OverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showOverflowMenu(context, ref),
      tooltip: 'Menu',
    );
  }

  void _showOverflowMenu(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && 
         MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Calculate max height (70% of screen)
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Menu items
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.bookmark_outline, color: AppColors.primary),
                    title: const Text('Bookmarks'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.bookmarks);
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.person_outline, color: AppColors.primary),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.profile);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.help_outline, color: AppColors.primary),
                    title: const Text('Help'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.help);
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.about);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout_outlined, color: AppColors.error),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      _logout(context, ref);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Store router reference before any async operations
    final router = GoRouter.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('📱 Logging out...');
      
      // Unregister device from push notifications
      if (_isMobilePlatform) {
        try {
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.unregisterToken();
        } catch (e) {
          debugPrint('📱 Failed to unregister push token: $e');
        }
      }
      
      // Clear local cache
      try {
        await MessageCacheService.clearCache();
        debugPrint('📱 Cache cleared');
      } catch (e) {
        debugPrint('📱 Failed to clear cache: $e');
      }
      
      // Clear bookmarks
      try {
        await BookmarksService.clearAll();
        debugPrint('📱 Bookmarks cleared');
      } catch (e) {
        debugPrint('📱 Failed to clear bookmarks: $e');
      }
      
      // Clear token
      try {
        final storage = ref.read(secureStorageProvider);
        await storage.delete(key: 'auth_token');
        ref.read(authTokenProvider.notifier).state = null;
        debugPrint('📱 Token cleared');
      } catch (e) {
        debugPrint('📱 Failed to clear token: $e');
      }

      // Navigate to login
      debugPrint('📱 Navigating to login');
      router.go(AppRoutes.login);
    }
  }
}
