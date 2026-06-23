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
              // Logo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                        gradient: AppColors.greenGlow, shape: BoxShape.circle),
                  ),
                  Image.asset(
                    'assets/images/lion_fm_logo.webp',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenTealGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.r20),
                      ),
                      alignment: Alignment.center,
                      child: Text('LF',
                          style: AppTextStyles.heroTitle
                              .copyWith(fontSize: 56, color: AppColors.bg0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p24),
              Text('Welcome to Lion FM', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text('Your Interactive Radio',
                  style: AppTextStyles.tagline
                      .copyWith(color: AppColors.electricTeal)),
              const SizedBox(height: 48),

              // Google — officially branded button
              _GoogleSignInButton(
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
                iconColor: const Color(0xFF1877F2),
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
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textDisabled),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.25,
              ),
            ),
          ],
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
  const _SSOButton(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.onTap});

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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12)),
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), -0.52, 1.05, true, paint);

    // Red arc (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), -2.62, 1.57, true, paint);

    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 1.05, 1.05, true, paint);

    // Green arc (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 2.09, 0.52, true, paint);

    // White centre cutout
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);

    // White horizontal bar (G crossbar)
    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - 0.5, center.dy - radius * 0.15, radius * 1.0, radius * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
