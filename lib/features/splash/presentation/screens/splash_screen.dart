import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';

/// Check if we're on a mobile platform
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Wait for animation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check if onboarding is complete
      bool onboardingComplete = false;
      try {
        onboardingComplete = await ref.read(onboardingCompleteProvider.future);
      } catch (e) {
        debugPrint('📱 Onboarding check error: $e');
      }

      if (!onboardingComplete) {
        if (mounted) context.go(AppRoutes.onboarding);
        return;
      }

      // Check for stored auth token
      String? token;
      try {
        token = await readAuthToken(ref);
      } catch (e) {
        debugPrint('📱 Auth token read error: $e');
      }

      if (token != null) {
        ref.read(authTokenProvider.notifier).state = token;

        // Token just restored — update badge immediately so it reflects current
        // unread count. Without this, the first badge update is skipped because
        // the notification service fires before the token is available.
        try {
          await ref.read(notificationServiceProvider).refreshBadge();
        } catch (e) {
          debugPrint('📱 Badge refresh after token restore failed (non-fatal): $e');
        }

        if (_isMobilePlatform) {
          try {
            final pushService = ref.read(pushNotificationServiceProvider);
            await pushService.initialize();
          } catch (e) {
            debugPrint('📱 Push notification init error: $e');
          }
        }

        // Navigate to pending deep link (notification tap) or home
        final pendingRoute = ref.read(pendingDeepLinkProvider);
        if (pendingRoute != null) {
          ref.read(pendingDeepLinkProvider.notifier).state = null;
          if (mounted) context.go(pendingRoute);
        } else {
          if (mounted) context.go(AppRoutes.home);
        }
      } else {
        if (mounted) context.go(AppRoutes.login);
      }
    } catch (e, stack) {
      debugPrint('📱 Splash navigation error: $e\n$stack');
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon - Atom style
                    const AtomLogo(
                      size: 120,
                      borderRadius: 24,
                    ),
                    const SizedBox(height: 32),
                    // App name
                    const Text(
                      'Nuclear MOTD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Message of the Day',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
