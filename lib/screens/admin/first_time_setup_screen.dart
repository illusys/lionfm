import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class FirstTimeSetupScreen extends ConsumerStatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  ConsumerState<FirstTimeSetupScreen> createState() =>
      _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends ConsumerState<FirstTimeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _nameCtrl.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/admin-login');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': _nameCtrl.text.trim(),
        'role': 'superAdmin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'self',
      });

      if (mounted) context.go('/admin');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Setup failed: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenTealGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.r16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.bg0, size: 36),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p24),
                  Text(
                    'Welcome to Lion FM\nAdmin Portal',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heroTitle,
                  ),
                  const SizedBox(height: AppDimensions.p12),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.p12),
                    decoration: BoxDecoration(
                      color: AppColors.lionGreen.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.r8),
                      border: Border.all(color: AppColors.borderGreen),
                    ),
                    child: Text(
                      'You are setting up admin access for the first time. '
                      'Your account will be assigned the Super Admin role.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.lionGreen),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p32),
                  Text('Display Name', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.p8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: AppTextStyles.body,
                    decoration: _inputDecoration('Your full name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  Text('Email', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.p8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.p16,
                      vertical: AppDimensions.p16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.r12),
                      border: Border.all(color: AppColors.border1),
                    ),
                    child: Text(
                      user?.email ?? '',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  Text('Role', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.p8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.p16,
                      vertical: AppDimensions.p12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lionGreen.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.r12),
                      border: Border.all(color: AppColors.borderGreen),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.lionGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Super Admin',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.lionGreen),
                        ),
                        const Spacer(),
                        Text('Locked', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lionGreen,
                        foregroundColor: AppColors.bg0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.r12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bg0,
                              ),
                            )
                          : Text('Complete Setup',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.bg0)),
                    ),
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
        borderSide:
            const BorderSide(color: AppColors.lionGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.p16,
        vertical: AppDimensions.p16,
      ),
    );
  }
}
