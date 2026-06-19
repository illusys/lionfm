import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/podcast_provider.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  static const _categories = [
    ('all', 'All'),
    ('health', 'Health'),
    ('tech', 'Tech'),
    ('news', 'News'),
    ('music', 'Music'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(podcastCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _categories[i];
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () =>
                ref.read(podcastCategoryProvider.notifier).state = value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.unnDeepBlue : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.rFull),
                border: Border.all(
                  color: isSelected ? AppColors.electricBlue : AppColors.border1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? AppColors.pureWhite
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
