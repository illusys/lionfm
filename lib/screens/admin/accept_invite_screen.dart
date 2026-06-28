import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String email;
  const AcceptInviteScreen({super.key, required this.email});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String _statusMsg = '';

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (widget.email.isEmpty) {
      _showError('Invalid invite link — email is missing.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMsg = 'Creating your account…';
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('No UID returned from Firebase Auth');

      setState(() => _statusMsg = 'Setting up your admin access…');

      // Poll for the users/{uid} doc created by the Cloud Function onAdminUserCreate
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            setState(() => _statusMsg = 'Access granted! Redirecting…');
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) context.go('/admin');
            return;
          }
        } catch (_) {}
      }

      // Cloud Function didn't respond in time
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please sign in with your new password.'),
          backgroundColor: AppColors.successGreen,
        ));
        context.go('/admin-login');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_authErrorMessage(e.code, e.message));
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; _statusMsg = ''; });
    }
  }

  String _authErrorMessage(String code, String? msg) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email already has an account. Use "Forgot password?" on the sign-in page.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with mixed case.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return msg ?? 'Something went wrong. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1639),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.p32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'FM',
                          style: TextStyle(
                            color: Color(0xFF15E0B4),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Stream',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.p24),
                Text(
                  'Activate Your Account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroTitle,
                ),
                const SizedBox(height: AppDimensions.p8),
                Text(
                  'FMStream Admin Portal',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.p32),
                // Email display (read-only)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16,
                    vertical: AppDimensions.p12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(AppDimensions.r12),
                    border: Border.all(color: AppColors.border1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_rounded, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  enabled: !_isLoading,
                  style: AppTextStyles.body,
                  decoration: _inputDecoration('Set password (min. 8 characters)').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  enabled: !_isLoading,
                  style: AppTextStyles.body,
                  decoration: _inputDecoration('Confirm password'),
                ),
                const SizedBox(height: AppDimensions.p24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15E0B4),
                      foregroundColor: const Color(0xFF06112B),
                      disabledBackgroundColor:
                          const Color(0xFF15E0B4).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg0),
                          )
                        : Text(
                            'Activate Account',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: const Color(0xFF06112B)),
                          ),
                  ),
                ),
                if (_isLoading && _statusMsg.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.p12),
                  Text(
                    _statusMsg,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal),
                  ),
                ],
                const SizedBox(height: AppDimensions.p24),
                Text(
                  'Authorized staff only. Your access level has been set by your admin.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
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
        borderSide: const BorderSide(color: Color(0xFF15E0B4), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.p16,
        vertical: AppDimensions.p16,
      ),
    );
  }
}
