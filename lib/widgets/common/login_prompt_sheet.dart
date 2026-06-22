import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginPromptSheet extends ConsumerWidget {
  final String reason;

  const LoginPromptSheet({super.key, required this.reason});

  static Future<void> show(BuildContext context, {required String reason}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.r20)),
      ),
      builder: (_) => LoginPromptSheet(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppColors.greenTealGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.bg0, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Sign In Required', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              reason,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Official Google sign-in button
            _GoogleSheetButton(
              onTap: () async {
                Navigator.pop(context);
                final authService = ref.read(authServiceProvider);
                await authService.signInWithGoogle();
              },
            ),
            const SizedBox(height: AppDimensions.p12),

            // Full login screen (email / other providers)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
                icon: const Icon(Icons.login, size: 18),
                label: const Text('More sign-in options'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.p12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continue Browsing',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSheetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSheetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
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
              width: 18,
              height: 18,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 14,
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), -0.52, 1.05, true, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), -2.62, 1.57, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 1.05, 1.05, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), 2.09, 0.52, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);

    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - 0.5, center.dy - radius * 0.15, radius * 1.0, radius * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
