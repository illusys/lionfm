import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/user_provider.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final initials = user.name.split(' ').map((w) => w[0]).take(2).join();

    return Container(
      margin: const EdgeInsets.all(AppDimensions.p16),
      padding: const EdgeInsets.all(AppDimensions.p20),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarMd,
            height: AppDimensions.avatarMd,
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials.toUpperCase(),
              style: AppTextStyles.h3.copyWith(color: AppColors.appBackground),
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.h3),
                Text(user.email, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.isPremium
                  ? AppColors.amberGold.withOpacity(0.2)
                  : AppColors.surface3,
              borderRadius: BorderRadius.circular(AppDimensions.rFull),
              border: Border.all(
                color: user.isPremium
                    ? AppColors.amberGold.withOpacity(0.5)
                    : AppColors.border2,
              ),
            ),
            child: Text(
              user.isPremium ? 'Premium ⭐' : 'Free',
              style: AppTextStyles.badgeText.copyWith(
                color: user.isPremium
                    ? AppColors.amberGold
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
