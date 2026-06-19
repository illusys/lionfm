import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/audio_provider.dart';
import '../../../widgets/common/live_badge.dart';
import '../../../widgets/common/loading_shimmer.dart';
import 'live_player_widget.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentShow = ref.watch(currentShowProvider);
    final streamStatus = ref.watch(streamStatusProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.p20,
        AppDimensions.p48,
        AppDimensions.p20,
        AppDimensions.p24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // Gold glow top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGlow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ON AIR NOW row
              Row(
                children: [
                  const LiveBadge(fontSize: 10),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.onAirNow,
                    style: AppTextStyles.liveLabel.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              // Show title
              currentShow.when(
                data: (show) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show?.title ?? 'Lion FM 91.1 MHz',
                      style: AppTextStyles.heroTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show?.hostName ?? 'Live Radio',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                loading: () => const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer(height: 28, width: 220),
                    SizedBox(height: 8),
                    LoadingShimmer(height: 14, width: 140),
                  ],
                ),
                error: (_, __) => Text(
                  'Lion FM 91.1 MHz',
                  style: AppTextStyles.heroTitle,
                ),
              ),
              const SizedBox(height: AppDimensions.p20),
              // Player controls
              currentShow.when(
                data: (show) => LivePlayerWidget(currentShow: show),
                loading: () => const LoadingShimmer(height: 120),
                error: (_, __) => const LivePlayerWidget(),
              ),
              // Listener count
              streamStatus.when(
                data: (status) => Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.p12),
                  child: Text(
                    '${status.listenerCount} listening now',
                    style: AppTextStyles.caption,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
