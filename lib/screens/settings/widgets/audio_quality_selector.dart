import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/user_provider.dart';

class AudioQualitySelector extends ConsumerWidget {
  const AudioQualitySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.audioQualitySection, style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          ...[
            (AudioQuality.dataSaver, AppStrings.dataSaver, AppStrings.dataSaverSubtitle, false),
            (AudioQuality.standard, AppStrings.standard, AppStrings.standardSubtitle, false),
            (AudioQuality.high, AppStrings.highQuality, AppStrings.highQualitySubtitle, !user.isPremium),
          ].map(((AudioQuality q, String title, String subtitle, bool locked) rec) {
            final (q, title, subtitle, locked) = rec;
            final isSelected = user.audioQuality == q;
            return GestureDetector(
              onTap: locked
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('High Quality requires Premium')),
                      )
                  : () => ref.read(userProvider.notifier).setAudioQuality(q),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: AppDimensions.p8),
                padding: const EdgeInsets.all(AppDimensions.p12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.r10),
                  border: Border(
                    left: BorderSide(
                      color: isSelected
                          ? AppColors.electricBlue
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: locked
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              )),
                          Text(subtitle, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (locked)
                      const Icon(Icons.lock_outline,
                          size: 16, color: AppColors.textTertiary)
                    else if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.electricBlue, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
