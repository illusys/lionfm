import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';
import '../../providers/schedule_provider.dart';
import 'live_badge.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackStateStreamProvider);
    final currentShow = ref.watch(currentShowProvider);
    final player = ref.watch(audioPlayerProvider);

    return GestureDetector(
      onTap: () => context.go('/'),
      child: Container(
        height: AppDimensions.miniPlayerHeight,
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          border: Border(top: BorderSide(color: AppColors.border1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppDimensions.r8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'FM',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.amberGold,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.p12),
            // Show info
            Expanded(
              child: currentShow.when(
                data: (show) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            show?.title ?? 'Lion FM 91.1 MHz',
                            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const LiveBadge(),
                      ],
                    ),
                    Text(
                      show?.hostName ?? 'Live Radio',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Text('Lion FM', style: AppTextStyles.body),
              ),
            ),
            // Play/Pause
            playbackState.when(
              data: (state) {
                final isPlaying = state.playing;
                final isLoading = state.processingState == ProcessingState.loading ||
                    state.processingState == ProcessingState.buffering;
                return GestureDetector(
                  onTap: () => isPlaying ? player.pause() : player.play(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.amberGold,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.appBackground,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.appBackground,
                            size: 20,
                          ),
                  ),
                );
              },
              loading: () => const SizedBox(width: 36, height: 36),
              error: (_, __) => const SizedBox(width: 36, height: 36),
            ),
          ],
        ),
      ),
    );
  }
}
