import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/ads/direct_banner_widget.dart';
import 'widgets/day_selector.dart';
import 'widgets/show_list_tile.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final shows = ref.watch(scheduledShowsStreamProvider(selectedDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.p16),
            child: Text(
              DateFormat('MMM d, y').format(DateTime.now()),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const DaySelector(),
          const Divider(height: 1),
          Expanded(
            child: shows.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        Text('No shows on $selectedDay',
                            style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          'The schedule will appear here once\nadmin adds shows.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.p8),
                  itemBuilder: (_, i) => ShowListTile(
                    show: list[i],
                    isLast: i == list.length - 1,
                    index: i,
                  ),
                );
              },
              loading: () => ListView(
                children: List.generate(
                    5,
                    (_) => const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.p16,
                              vertical: AppDimensions.p8),
                          child: LoadingShimmer(height: 60),
                        )),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Could not load schedule',
                onRetry: () => ref
                    .refresh(scheduledShowsStreamProvider(selectedDay)),
              ),
            ),
          ),
          const DirectBannerWidget(placement: 'schedule_bottom'),
        ],
      ),
    );
  }
}
