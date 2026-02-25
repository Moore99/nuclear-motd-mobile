import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';

/// Stores a pending deep link route from a notification tap in terminated state.
/// Splash screen reads this after auth is confirmed and navigates there.
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService, ref);
});

/// Service for handling push notifications and app icon badge
class NotificationService {
  final ApiService _apiService;
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // Null on iOS — instantiating FlutterLocalNotificationsPlugin on iOS hijacks
  // UNUserNotificationCenter delegate, blocking Firebase from receiving the
  // APNs token and making getToken() return null.
  final FlutterLocalNotificationsPlugin? _localNotifications;
  Timer? _syncTimer;
  static const String _badgeChannelId = 'badge_channel';
  static const String _badgeChannelName = 'App Badge';
  static const String _alertChannelId = 'nuclear_motd_alerts';
  static const String _alertChannelName = 'Nuclear MOTD Notifications';

  NotificationService(this._apiService, this._ref)
      : _localNotifications =
            (!kIsWeb && Platform.isAndroid) ? FlutterLocalNotificationsPlugin() : null;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (!notificationsEnabled) {
        return;
      }

      // Initialize local notifications for Android (Samsung badge support)
      if (Platform.isAndroid) {
        await _initializeLocalNotifications();
      }

      // Request notification permissions
      try {
        await _requestPermissions();
      } catch (e) {
        debugPrint('📱 Notification permission error (non-fatal): $e');
      }

      // Initialize Firebase messaging
      try {
        await _initializeMessaging();
      } catch (e) {
        debugPrint('📱 Firebase messaging init error (non-fatal): $e');
      }

      // Start periodic sync for unread count
      _startPeriodicSync();
    } catch (e) {
      debugPrint('📱 Notification service init error (non-fatal): $e');
    }
  }

  /// Initialize local notifications for Android (Samsung badge support)
  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('📱 Initializing local notifications...');
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications!.initialize(settings: initSettings);
      debugPrint('📱 Local notifications initialized');

      // Create a notification channel for badge updates
      const androidChannel = AndroidNotificationChannel(
        _badgeChannelId,
        _badgeChannelName,
        description: 'Notifications for app badge (can be hidden in system settings)',
        importance: Importance.low, // Low importance = silent notifications section
        showBadge: true, // Enable badge for this channel
        playSound: false,
        enableVibration: false,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // High-importance channel for visible push notification alerts
      const alertChannel = AndroidNotificationChannel(
        _alertChannelId,
        _alertChannelName,
        description: 'Daily nuclear industry insights and updates',
        importance: Importance.high,
        showBadge: true,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alertChannel);

      debugPrint('📱 Local notification channels created');
    } catch (e) {
      debugPrint('📱 Error initializing local notifications: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('📱 User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('📱 User granted provisional notification permissions');
    } else {
      debugPrint('📱 User declined or has not accepted notification permissions');
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeMessaging() async {
    // Get FCM token and register with backend
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token obtained, registering with backend...');
      await _registerToken(token);
    }

    // Re-register when token rotates
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('📱 FCM Token refreshed, re-registering...');
      _registerToken(newToken);
    });

    // Handle foreground messages — show a heads-up notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Received foreground message: ${message.notification?.title}');
      _showForegroundNotification(message);
      _updateBadge();
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification opened: ${message.notification?.title}');
      _navigateToMessage(message);
    });

    // Handle when app is opened from terminated state — store as pending deep
    // link; splash screen navigates there after auth is confirmed
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from terminated state via notification');
        final messageIdStr = message.data['message_id'];
        final messageId = messageIdStr != null ? int.tryParse(messageIdStr) : null;
        final route = messageId != null ? '/messages/$messageId' : AppRoutes.messages;
        _ref.read(pendingDeepLinkProvider.notifier).state = route;
        debugPrint('📱 Stored pending deep link: $route');
      }
    });
  }

  /// Send FCM token to backend
  Future<void> _registerToken(String token) async {
    try {
      // Skip if not authenticated — called again explicitly after login
      final authToken = _ref.read(authTokenProvider);
      if (authToken == null) {
        debugPrint('📱 Skipping FCM registration — not authenticated yet');
        return;
      }
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _apiService.registerFcmToken(token, platform);
      debugPrint('📱 FCM token registered with backend ($platform)');
    } catch (e) {
      debugPrint('📱 FCM token registration error (non-fatal): $e');
    }
  }

  /// Register FCM token after login (call once auth token is available)
  Future<void> registerTokenAfterLogin() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('📱 Post-login FCM registration error (non-fatal): $e');
    }
  }

  /// Navigate to message detail screen when a notification is tapped
  void _navigateToMessage(RemoteMessage message) {
    try {
      final messageIdStr = message.data['message_id'];
      if (messageIdStr == null) {
        debugPrint('📱 Notification tap: no message_id in data, going to messages list');
        _ref.read(appRouterProvider).go(AppRoutes.messages);
        return;
      }
      final messageId = int.tryParse(messageIdStr);
      if (messageId == null) {
        debugPrint('📱 Notification tap: invalid message_id "$messageIdStr"');
        _ref.read(appRouterProvider).go(AppRoutes.messages);
        return;
      }
      debugPrint('📱 Navigating to message $messageId');
      _ref.read(appRouterProvider).go('/messages/$messageId');
    } catch (e) {
      debugPrint('📱 Navigation error: $e');
    }
  }

  /// Show a visible heads-up notification when a push arrives in the foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final androidDetails = AndroidNotificationDetails(
        _alertChannelId,
        _alertChannelName,
        channelDescription: 'Daily nuclear industry insights and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);
      await _localNotifications!.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: notificationDetails,
      );
      debugPrint('📱 Foreground notification displayed: ${notification.title}');
    } catch (e) {
      debugPrint('📱 Error showing foreground notification: $e');
    }
  }

  /// Update app icon badge with current unread count
  Future<void> _updateBadge() async {
    try {
      // Check if user is authenticated
      final token = _ref.read(authTokenProvider);
      if (token == null) {
        debugPrint('📱 User not authenticated, skipping badge update');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final badgeEnabled = prefs.getBool('badge_enabled') ?? true;

      if (!badgeEnabled) {
        debugPrint('📱 Badge disabled in settings');
        // Remove badge if disabled
        await AppBadgePlus.updateBadge(0);
        return;
      }

      // Fetch unread count from API
      final unreadCount = await _apiService.getUnreadCount();
      debugPrint('📱 Unread count fetched: $unreadCount');

      // Update app icon badge
      if (unreadCount > 0) {
        await AppBadgePlus.updateBadge(unreadCount);
        // Samsung devices also need a silent notification to show the badge
        if (Platform.isAndroid) {
          await _postSilentNotification(unreadCount);
        }
        debugPrint('📱 Badge updated to: $unreadCount');
      } else {
        await AppBadgePlus.updateBadge(0);
        if (Platform.isAndroid) {
          await _localNotifications!.cancelAll();
        }
        debugPrint('📱 Badge removed (count is 0)');
      }
    } catch (e) {
      // Log the error but don't throw - network errors during periodic sync
      // shouldn't disrupt the user experience
      debugPrint('📱 Error updating badge (will retry later): $e');
      // Silently fail - the next periodic update will retry
    }
  }

  /// Post a silent persistent notification for Samsung badge support (Android only).
  Future<void> _postSilentNotification(int count) async {
    try {
      // Guard: skip if notification permission not granted — avoids Samsung
      // "not authorized to use this function" system toast on first launch.
      final androidImpl = _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final permitted = await androidImpl?.areNotificationsEnabled() ?? false;
      if (!permitted) {
        debugPrint('📱 Skipping silent notification — permission not granted');
        return;
      }

      debugPrint('📱 Posting silent notification with count: $count');
      final androidDetails = AndroidNotificationDetails(
        _badgeChannelId,
        _badgeChannelName,
        channelDescription: 'Silent notifications for app badge',
        importance: Importance.min,
        priority: Priority.min,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        number: count,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);
      await _localNotifications!.show(
        id: 0,
        title: 'Nuclear MOTD',
        body: '$count unread message${count != 1 ? 's' : ''}',
        notificationDetails: notificationDetails,
      );
      debugPrint('📱 Silent notification posted successfully with count: $count');
    } catch (e) {
      debugPrint('📱 Error posting silent notification: $e');
    }
  }

  /// Start periodic sync to keep badge updated
  void _startPeriodicSync() {
    // Update immediately
    _updateBadge();

    // Update every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateBadge();
    });
  }

  /// Manually refresh badge (call when messages are read)
  Future<void> refreshBadge() async {
    await _updateBadge();
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await _requestPermissions();
      await _initializeMessaging();
      _startPeriodicSync();
    } else {
      _syncTimer?.cancel();
      debugPrint('📱 Notifications disabled');
    }
  }

  /// Enable/disable badge
  Future<void> setBadgeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('badge_enabled', enabled);

    if (enabled) {
      await _updateBadge();
    } else {
      await AppBadgePlus.updateBadge(0);
      debugPrint('📱 Badge disabled');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Check if badge is enabled
  Future<bool> isBadgeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('badge_enabled') ?? true;
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}
