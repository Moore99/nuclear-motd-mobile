import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import '../network/dio_client.dart';

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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Timer? _syncTimer;
  static const String _badgeChannelId = 'badge_channel';
  static const String _badgeChannelName = 'App Badge';

  NotificationService(this._apiService, this._ref);

  /// Initialize notification service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) {
      return;
    }

    // Initialize local notifications for Samsung badge support
    if (Platform.isAndroid) {
      await _initializeLocalNotifications();
    }

    // Request notification permissions
    await _requestPermissions();

    // Initialize Firebase messaging
    await _initializeMessaging();

    // Start periodic sync for unread count
    _startPeriodicSync();
  }

  /// Initialize local notifications (required for Samsung badge support)
  Future<void> _initializeLocalNotifications() async {
    try {
      print('📱 Initializing local notifications...');
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(settings: initSettings);
      print('📱 Local notifications initialized');

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

      print('📱 Local notification channel created for badge support');
    } catch (e) {
      print('📱 Error initializing local notifications: $e');
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
      print('📱 User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('📱 User granted provisional notification permissions');
    } else {
      print('📱 User declined or has not accepted notification permissions');
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeMessaging() async {
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      print('📱 FCM Token: $token');
      // TODO: Send token to backend to register for push notifications
      // await _apiService.registerFcmToken(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Received foreground message: ${message.notification?.title}');
      // When a new message arrives, refresh the unread count
      _updateBadge();
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notification opened: ${message.notification?.title}');
      // Navigate to messages screen
      // TODO: Use router to navigate to messages
    });

    // Handle when app is opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App opened from terminated state');
        // Navigate to messages screen
      }
    });
  }

  /// Update app icon badge with current unread count
  Future<void> _updateBadge() async {
    try {
      // Check if user is authenticated
      final token = _ref.read(authTokenProvider);
      if (token == null) {
        print('📱 User not authenticated, skipping badge update');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final badgeEnabled = prefs.getBool('badge_enabled') ?? true;

      if (!badgeEnabled) {
        print('📱 Badge disabled in settings');
        // Remove badge if disabled
        await AppBadgePlus.updateBadge(0);
        return;
      }

      // Fetch unread count from API
      final unreadCount = await _apiService.getUnreadCount();
      print('📱 Unread count fetched: $unreadCount');

      // Update app icon badge
      if (unreadCount > 0) {
        // Try to update badge count (works on most devices)
        await AppBadgePlus.updateBadge(unreadCount);

        // For Samsung devices, also post a silent notification with badge number
        if (Platform.isAndroid) {
          await _postSilentNotification(unreadCount);
        }

        print('📱 Badge updated to: $unreadCount');
      } else {
        await AppBadgePlus.updateBadge(0);

        // Cancel all notifications to clear badge on Samsung
        if (Platform.isAndroid) {
          await _localNotifications.cancelAll();
        }

        print('📱 Badge removed (count is 0)');
      }
    } catch (e) {
      // Log the error but don't throw - network errors during periodic sync
      // shouldn't disrupt the user experience
      print('📱 Error updating badge (will retry later): $e');
      // Silently fail - the next periodic update will retry
    }
  }

  /// Post a silent notification with badge count (for Samsung devices)
  Future<void> _postSilentNotification(int count) async {
    try {
      print('📱 Posting silent notification with count: $count');
      final androidDetails = AndroidNotificationDetails(
        _badgeChannelId,
        _badgeChannelName,
        channelDescription: 'Silent notifications for app badge',
        importance: Importance.min, // Use minimum importance instead of low
        priority: Priority.min,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        ongoing: true, // Make it persistent so it stays
        autoCancel: false, // Don't auto-cancel
        number: count, // This sets the badge number on Samsung
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Always use ID 0 so we only have one silent notification
      await _localNotifications.show(
        id: 0,
        title: 'Nuclear MOTD', // Non-empty title required for badge on Samsung
        body: '$count unread message${count != 1 ? 's' : ''}', // Non-empty body
        notificationDetails: notificationDetails,
      );

      print('📱 Silent notification posted successfully with count: $count');
    } catch (e) {
      print('📱 Error posting silent notification: $e');
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
      print('📱 Notifications disabled');
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
      print('📱 Badge disabled');
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
