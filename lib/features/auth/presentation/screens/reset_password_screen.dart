import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import 'forgot_password_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isVerifying = true;
  bool _tokenValid = false;
  bool _resetSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '${AppConfig.authVerifyResetToken}/${widget.token}',
      );

      final data = response.data;
      setState(() {
        _isVerifying = false;
        _tokenValid = data['valid'] == true;
        if (!_tokenValid) {
          _errorMessage = data['message'] ?? 'Invalid or expired reset link.';
        }
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _tokenValid = false;
        _errorMessage = 'Failed to verify reset link. Please try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        AppConfig.authResetPassword,
        data: {
          'token': widget.token,
          'new_password': _passwordController.text,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        setState(() {
          _resetSuccess = true;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to reset password.';
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Reset Password'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isVerifying
              ? _buildVerifying()
              : _resetSuccess
                  ? _buildSuccessView()
                  : _tokenValid
                      ? _buildForm()
                      : _buildInvalidToken(),
        ),
      ),
    );
  }

  Widget _buildVerifying() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Verifying reset link...',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidToken() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.link_off_outlined,
            size: 56,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Invalid Reset Link',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMessage ?? 'This password reset link is invalid or has expired.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Request New Link'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Password Reset!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Your password has been successfully reset. You can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Sign In Now'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Create New Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter a strong password for your account.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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

          // Password requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_outlined, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Password Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• At least 8 characters\n• At least one uppercase letter\n• At least one lowercase letter\n• At least one number\n• At least one special character (!@#\$%^&*)',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // New password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!value.contains(RegExp(r'[A-Z]'))) {
                return 'Password must contain an uppercase letter';
              }
              if (!value.contains(RegExp(r'[a-z]'))) {
                return 'Password must contain a lowercase letter';
              }
              if (!value.contains(RegExp(r'[0-9]'))) {
                return 'Password must contain a number';
              }
              if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                return 'Password must contain a special character';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
