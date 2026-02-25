import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../profile/presentation/screens/about_screen.dart';
import 'forgot_password_screen.dart';

/// Check if we're on a mobile platform that supports biometrics
bool get _supportsBiometrics {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canUseBiometrics = false;
  bool _hasSavedCredentials = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_supportsBiometrics) {
      _checkBiometrics();
    }
    _loadSavedCredentials();
  }

  Future<void> _checkBiometrics() async {
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

  Future<void> _loadSavedCredentials() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final savedEmail = await storage.read(key: 'saved_email');
      final savedPassword = await storage.read(key: 'saved_password');

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _emailController.text = savedEmail;
          _hasSavedCredentials = true;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Handle decryption errors (e.g., after app reinstall)
      debugPrint('Error loading saved credentials: $e');
      // Clear corrupted secure storage
      try {
        final storage = ref.read(secureStorageProvider);
        await storage.deleteAll();
      } catch (e2) {
        debugPrint('Error clearing secure storage: $e2');
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to Nuclear MOTD',
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        final storage = ref.read(secureStorageProvider);
        final savedEmail = await storage.read(key: 'saved_email');
        final savedPassword = await storage.read(key: 'saved_password');
        
        if (savedEmail != null && savedPassword != null) {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          await _login();
        }
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        AppConfig.authLogin,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      final data = response.data;
      if (data['success'] == true && data['access_token'] != null) {
        // Store token (SecureStorage + SharedPreferences backup)
        await saveAuthToken(ref, data['access_token']);

        // Update provider
        ref.read(authTokenProvider.notifier).state = data['access_token'];

        // Always save credentials � needed for silent re-login on 401
        // and for biometric login on next app open.
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'saved_email', value: _emailController.text.trim());
        await storage.write(key: 'saved_password', value: _passwordController.text);

        // DIAGNOSTIC: confirm post-login code runs and dioProvider works
        // Keep diagDio in scope so we can pass it to registerTokenAfterLogin
        final diagDio = ref.read(dioProvider);
        try {
          await diagDio.post('/device/push-diagnostic',
              data: {'stage': 'login-screen', 'auth': 'ok'});
          debugPrint('📱 Login-screen diagnostic sent');
        } catch (e) {
          debugPrint('📱 Login-screen diagnostic error: $e');
        }

        // Firebase-only step: get FCM token (no Dio inside — Dio from
        // NotificationService fails silently on iOS).
        final notificationService = ref.read(notificationServiceProvider);
        Map<String, dynamic> rtalResult = {'status': 'not-called', 'token': null};
        try {
          rtalResult = await notificationService.registerTokenAfterLogin();
        } catch (e) {
          rtalResult = {'status': 'threw:${e.toString().substring(0, 80)}', 'token': null};
        }

        // Report result using our working Dio (from login_screen WidgetRef).
        try {
          await diagDio.post('/device/push-diagnostic', data: {
            'stage': 'rtal-result',
            'result': rtalResult['status'],
          });
        } catch (e) {
          debugPrint('📱 rtal-result diagnostic error: $e');
        }

        // Register FCM token using our working Dio.
        final fcmToken = rtalResult['token'] as String?;
        if (fcmToken != null) {
          try {
            final platform = Platform.isIOS ? 'ios' : 'android';
            await diagDio.post(
              AppConfig.deviceRegister,
              data: {'fcm_token': fcmToken, 'platform': platform},
            );
            debugPrint('📱 FCM token registered via login_screen Dio');
          } catch (e) {
            debugPrint('📱 FCM token registration error: $e');
          }
        }

        try {
          await notificationService.refreshBadge();
        } catch (e) {
          debugPrint('📱 Badge refresh error: $e');
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
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.friendlyMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo and title
                const Center(
                  child: AtomLogo(
                    size: 80,
                    borderRadius: 16,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nuclear Message of the Day',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // App description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha:isDark ? 0.2 : 0.08),
                        AppColors.primary.withValues(alpha:isDark ? 0.1 : 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha:isDark ? 0.3 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Receive messages and industry insights targeted at nuclear professionals at your desired frequency. Sign up, choose your topics and schedule, and your insights will start rolling in!',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Learn more about Nuclear MOTD',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Remember me & Forgot password row
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember me',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                
                // Biometric login button (only on mobile with saved credentials)
                if (_supportsBiometrics && _canUseBiometrics && _hasSavedCredentials) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Sign in with Biometrics'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.signup),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
