import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/user_provider.dart';

class DirectBannerWidget extends ConsumerWidget {
  final String placement;
  final double height;
  const DirectBannerWidget({super.key, required this.placement, this.height = 80});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user.isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(
              child: Text(
                'Lion FM Partner Ad',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
            Positioned(
              top: 6,
              right: 8,
              child: Text('AD', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
