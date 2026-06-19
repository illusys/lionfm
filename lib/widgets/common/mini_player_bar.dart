import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';
import '../../providers/schedule_provider.dart';

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
        height: 68,
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          border: Border(top: BorderSide(color: AppColors.borderGreen, width: 1)),
        ),
        child: Column(
          children: [
            // Thin animated progress bar at top
            const LinearProgressIndicator(
              value: null,
              backgroundColor: AppColors.bg3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lionGreen),
              minHeight: 2,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
                child: Row(
                  children: [
                    // Artwork
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenTealGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.r8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'FM',
                        style: AppTextStyles.label.copyWith(color: AppColors.bg0, fontSize: 12),
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
                            Text(
                              show?.title ?? 'Lion FM 91.1 MHz',
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              show?.hostName ?? 'Live Radio',
                              style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => Text('Lion FM', style: AppTextStyles.body),
                      ),
                    ),
                    // Play/pause
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
                              gradient: AppColors.greenTealGradient,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: isLoading
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg0),
                                  )
                                : Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: AppColors.bg0,
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
            ),
          ],
        ),
      ),
    );
  }
}
