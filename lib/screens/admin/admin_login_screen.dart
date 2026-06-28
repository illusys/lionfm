import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/current_station_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call Firebase FIRST — nothing else before this
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      debugPrint('SIGNIN SUCCESS: uid=${credential.user?.uid}');

      // Give the auth state a moment to propagate, then navigate.
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final stationId = ref.read(currentStationIdProvider);
      final adminUser = ref.read(adminUserProvider).valueOrNull;
      if (adminUser != null &&
          adminUser.isPlatformOwner &&
          stationId == null) {
        context.go('/platform');
      } else {
        context.go('/admin');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('SIGNIN FirebaseAuthException: ${e.code} ${e.message}');
      if (mounted) _showError('${e.code}: ${e.message ?? "Auth failed"}');
    } catch (e, stack) {
      debugPrint('SIGNIN OTHER ERROR: $e\n$stack');
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter your email above first'),
      ));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'Error sending reset email'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.p32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/lion_fm_logo.webp',
                      width: 120,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.greenTealGradient,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.r16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'LF',
                          style: AppTextStyles.h1
                              .copyWith(color: AppColors.bg0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p24),
                  Text(
                    'Admin Portal',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heroTitle,
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  Text(
                    'Lion FM 91.1 MHz — Staff Access',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.p40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.body,
                    decoration: _inputDecoration('Email address'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: AppTextStyles.body,
                    decoration: _inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.electricTeal),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lionGreen,
                        foregroundColor: AppColors.bg0,
                        disabledBackgroundColor:
                            AppColors.lionGreen.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.r12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bg0,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.bg0),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p32),
                  Text(
                    'Authorized staff only. Unauthorized access is prohibited.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        borderSide: const BorderSide(color: AppColors.border1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        borderSide: const BorderSide(color: AppColors.border1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        borderSide: const BorderSide(color: AppColors.lionGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.p16,
        vertical: AppDimensions.p16,
      ),
    );
  }
}
