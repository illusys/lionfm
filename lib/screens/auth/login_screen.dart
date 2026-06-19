import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(gradient: AppColors.greenGlow, shape: BoxShape.circle),
                  ),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenTealGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.r20),
                    ),
                    alignment: Alignment.center,
                    child: Text('LF', style: AppTextStyles.heroTitle.copyWith(fontSize: 56, color: AppColors.bg0)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p24),
              Text('Welcome to Lion FM', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text('Your Interactive Radio', style: AppTextStyles.tagline.copyWith(color: AppColors.electricTeal)),
              const SizedBox(height: 48),

              // Google
              _SSOButton(
                icon: Icons.g_mobiledata_rounded,
                iconColor: Colors.red,
                label: 'Continue with Google',
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  final result = await authService.signInWithGoogle();
                  if (result != null && context.mounted) context.go('/');
                },
              ),
              const SizedBox(height: AppDimensions.p12),

              // Facebook
              _SSOButton(
                icon: Icons.facebook_rounded,
                iconColor: Color(0xFF1877F2),
                label: 'Continue with Facebook',
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  final result = await authService.signInWithFacebook();
                  if (result != null && context.mounted) context.go('/');
                },
              ),
              const SizedBox(height: AppDimensions.p24),

              Row(children: [
                const Expanded(child: Divider(color: AppColors.border1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: AppTextStyles.caption),
                ),
                const Expanded(child: Divider(color: AppColors.border1)),
              ]),
              const SizedBox(height: AppDimensions.p24),

              // Guest mode
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(isGuestModeProvider.notifier).state = true;
                    context.go('/');
                  },
                  child: const Text('Continue without account'),
                ),
              ),
              const SizedBox(height: AppDimensions.p24),
              Text(
                'By continuing you agree to our Privacy Policy',
                style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SSOButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SSOButton({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.bg2,
          side: const BorderSide(color: AppColors.border1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
