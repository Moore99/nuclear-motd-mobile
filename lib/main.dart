import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/notification_service.dart';
import 'features/messages/messages_provider.dart';
import 'core/cache/message_cache_service.dart';
import 'core/services/bookmarks_service.dart';

/// Check if we're on a mobile platform that supports ads
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch ALL unhandled Flutter errors instead of crashing
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('📱 FLUTTER ERROR: ${details.exception}');
    debugPrint('📱 STACK: ${details.stack}');
  };

  // Catch ALL unhandled async/platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('📱 PLATFORM ERROR: $error');
    debugPrint('📱 STACK: $stack');
    return true; // returning true prevents the crash
  };

  // Enable edge-to-edge on Android 15+
  if (!kIsWeb && Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  try {
    // Initialize Hive for local storage
    debugPrint('📱 Initializing Hive...');
    await Hive.initFlutter();

    // Initialize message cache
    debugPrint('📱 Initializing message cache...');
    await MessageCacheService.initialize();

    // Initialize bookmarks
    debugPrint('📱 Initializing bookmarks...');
    await BookmarksService.initialize();

    // Initialize Mobile Ads SDK (Android only for now - iOS pending AdMob review)
    if (_isMobilePlatform && !Platform.isIOS) {
      debugPrint('📱 Initializing Mobile Ads...');
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('📱 Mobile Ads init error (non-fatal): $e');
      }
    }

    // Initialize Firebase (only on mobile)
    if (_isMobilePlatform) {
      debugPrint('📱 Initializing Firebase...');
      try {
        await Firebase.initializeApp();
        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        debugPrint('📱 Firebase initialized successfully');
      } catch (e) {
        debugPrint('📱 Firebase init error (non-fatal): $e');
      }
    }

    debugPrint('📱 Starting app...');
    runApp(
      const ProviderScope(
        child: NuclearMotdApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('📱 FATAL ERROR during initialization: $e');
    debugPrint('📱 Stack trace: $stackTrace');

    // Show error app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to start app:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NuclearMotdApp extends ConsumerStatefulWidget {
  const NuclearMotdApp({super.key});

  @override
  ConsumerState<NuclearMotdApp> createState() => _NuclearMotdAppState();
}

class _NuclearMotdAppState extends ConsumerState<NuclearMotdApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize().catchError((e) {
        debugPrint('📱 Failed to initialize notification service: $e');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the home screen badge in sync with the local unread count.
    // badgeSyncProvider watches unreadCountProvider and calls
    // AppBadgePlus.updateBadge() whenever the count changes.
    ref.watch(badgeSyncProvider);

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
