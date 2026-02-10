import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Secure storage for auth tokens
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Auth token provider
final authTokenProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Token helpers – persist / restore from SecureStorage + SharedPreferences backup
// ---------------------------------------------------------------------------

/// Save token to both secure storage and SharedPreferences (backup).
Future<void> saveAuthToken(dynamic ref, String token) async {
  try {
    await ref.read(secureStorageProvider).write(key: 'auth_token', value: token);
  } catch (e) {
    debugPrint('Token SecureStorage write failed (non-fatal): $e');
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token_backup', token);
  debugPrint('Auth token saved');
}

/// Delete token from both stores and clear provider.
Future<void> clearAuthToken(dynamic ref) async {
  try {
    await ref.read(secureStorageProvider).delete(key: 'auth_token');
  } catch (e) {
    debugPrint('Token SecureStorage delete failed (non-fatal): $e');
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token_backup');
  ref.read(authTokenProvider.notifier).state = null;
  debugPrint('Auth token cleared');
}

/// Read token: SecureStorage first, fall back to SharedPreferences backup.
Future<String?> readAuthToken(dynamic ref) async {
  try {
    final token = await ref.read(secureStorageProvider).read(key: 'auth_token');
    if (token != null) return token;
  } catch (e) {
    debugPrint('Token SecureStorage read failed, trying backup: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token_backup');
}

/// Dio HTTP client provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(ref));

  // Add logging interceptor (debug only)
  assert(() {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
    return true;
  }());

  return dio;
});

/// Auth interceptor – attaches JWT and silently re-logins on 401.
class AuthInterceptor extends Interceptor {
  final Ref ref;
  bool _isRefreshing = false;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(authTokenProvider);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await _silentReLogin();
        if (newToken != null) {
          debugPrint('Silent re-login succeeded, retrying request');
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          // Use a plain Dio to retry so we don't recurse through this interceptor
          final plainDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          final response = await plainDio.fetch(options);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        debugPrint('Silent re-login error: $e');
      } finally {
        _isRefreshing = false;
      }

      // Re-login failed – clear token; router redirect will send to login
      debugPrint('401 unrecoverable – clearing token');
      await clearAuthToken(ref);
    }
    handler.next(err);
  }

  /// Attempt silent re-login using stored credentials. Returns new token or null.
  Future<String?> _silentReLogin() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final email = await storage.read(key: 'saved_email');
      final password = await storage.read(key: 'saved_password');
      if (email == null || password == null) {
        debugPrint('No saved credentials available for silent re-login');
        return null;
      }

      debugPrint('Attempting silent re-login for $email');
      final plainDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await plainDio.post(
        AppConfig.authLogin,
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (data['success'] == true && data['access_token'] != null) {
        final newToken = data['access_token'] as String;
        await saveAuthToken(ref, newToken);
        ref.read(authTokenProvider.notifier).state = newToken;
        return newToken;
      }
    } catch (e) {
      debugPrint('Silent re-login request failed: $e');
    }
    return null;
  }
}

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Extension to handle Dio errors gracefully
extension DioErrorHandler on DioException {
  String get friendlyMessage {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final responseData = response?.data;

        if (statusCode == 401) {
          return 'Session expired. Please log in again.';
        } else if (statusCode == 403) {
          return 'You don\'t have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'The requested resource was not found.';
        } else if (statusCode == 429) {
          return 'Too many requests. Please wait a few minutes and try again.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }

        // Check for rate limit in HTML response
        if (responseData is String && responseData.contains('Rate Limit Exceeded')) {
          return 'Too many requests. Please wait a few minutes and try again.';
        }

        // Try to get message from response
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'] as String;
        }
        if (responseData is Map && responseData.containsKey('detail')) {
          return responseData['detail'] as String;
        }

        return 'An error occurred. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
