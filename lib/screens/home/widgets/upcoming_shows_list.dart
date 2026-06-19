import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/schedule_provider.dart';

class UpcomingShowsList extends ConsumerWidget {
  const UpcomingShowsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingShowsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.upNext, style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          upcoming.when(
            data: (shows) {
              if (shows.isEmpty) {
                return Text(
                  'No more shows today',
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textTertiary),
                );
              }
              return Column(
                children: [
                  ...shows.map((show) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppDimensions.p8),
                        child: Row(
                          children: [
                            Text(
                              show.timeRange.split('–').first.trim(),
                              style: AppTextStyles.mono.copyWith(
                                  color: AppColors.textTertiary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: AppColors.border2,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(show.title,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                  Text(show.hostName,
                                      style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface3,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.rFull),
                                border:
                                    Border.all(color: AppColors.border2),
                              ),
                              child: Text('NEXT',
                                  style: AppTextStyles.badgeText
                                      .copyWith(color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppDimensions.p8),
          TextButton(
            onPressed: () => context.go('/schedule'),
            child: const Text('View full schedule →'),
          ),
        ],
      ),
    );
  }
}
