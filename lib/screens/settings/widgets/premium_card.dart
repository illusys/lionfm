import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/user_provider.dart';

class PremiumCard extends ConsumerWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user.isPremium) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      padding: const EdgeInsets.all(AppDimensions.p20),
      decoration: BoxDecoration(
        color: AppColors.goldTint.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.amberGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.goPremium,
              style: AppTextStyles.h3.copyWith(color: AppColors.amberGold)),
          const SizedBox(height: 6),
          Text(AppStrings.premiumSubtitle,
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppDimensions.p12),
          ...[
            'Ad-free listening',
            'Offline episode downloads',
            'Priority song request queue',
            'Exclusive event streams',
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Text('✓ ',
                      style: TextStyle(color: AppColors.amberGold)),
                  Text(f, style: AppTextStyles.bodySmall),
                ]),
              )),
          const SizedBox(height: AppDimensions.p16),
          Row(
            children: [
              Text(
                '₦1,000',
                style: AppTextStyles.h1.copyWith(color: AppColors.pureWhite),
              ),
              Text(' / month', style: AppTextStyles.caption),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Simulate payment for demo
                  ref.read(userProvider.notifier).updatePremiumStatus(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.welcomePremium)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Go Premium'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
