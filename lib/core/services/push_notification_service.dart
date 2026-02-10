import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message: ${message.messageId}');
}

/// FCM Token provider
final fcmTokenProvider = StateProvider<String?>((ref) => null);

/// Notification permission provider
final notificationPermissionProvider = StateProvider<bool>((ref) => false);

/// Push notification service
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Ref _ref;
  
  PushNotificationService(this._ref);
  
  /// Initialize push notifications
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    
    _ref.read(notificationPermissionProvider.notifier).state = granted;
    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
    
    if (!granted) {
      debugPrint('📱 Notifications not authorized');
      return;
    }
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      _ref.read(fcmTokenProvider.notifier).state = token;
      debugPrint('📱 FCM Token: $token');
      
      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // Register token with backend
      await _registerTokenWithBackend(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('📱 FCM Token refreshed: $newToken');
      _ref.read(fcmTokenProvider.notifier).state = newToken;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      
      await _registerTokenWithBackend(newToken);
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    
    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }
  
  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post(
        '/device/register',
        data: {
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
      debugPrint('📱 FCM token registered with backend');
    } catch (e) {
      debugPrint('📱 Failed to register FCM token: $e');
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message: ${message.notification?.title}');
    
    // You can show a local notification or update UI here
    // For now, we'll just log it
    final notification = message.notification;
    if (notification != null) {
      debugPrint('📱 Title: ${notification.title}');
      debugPrint('📱 Body: ${notification.body}');
    }
    
    // Handle data payload
    if (message.data.isNotEmpty) {
      debugPrint('📱 Data: ${message.data}');
    }
  }
  
  /// Handle notification tap (from background/terminated state)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('📱 Message tap: ${message.data}');
    
    // Navigate to specific screen based on data
    final data = message.data;
    if (data.containsKey('message_id')) {
      // Could navigate to message detail screen
      // This would require access to navigation context
      debugPrint('📱 Should navigate to message: ${data['message_id']}');
    }
  }
  
  /// Unregister device token (call on logout)
  Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      
      if (token != null) {
        final dio = _ref.read(dioProvider);
        await dio.post(
          '/device/unregister',
          data: {'fcm_token': token},
        );
        await prefs.remove('fcm_token');
        debugPrint('📱 FCM token unregistered');
      }
    } catch (e) {
      debugPrint('📱 Failed to unregister FCM token: $e');
    }
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('📱 Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('📱 Unsubscribed from topic: $topic');
  }
}

/// Push notification service provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
