import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/show_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/user_provider.dart';
import 'waveform_widget.dart';

class LivePlayerWidget extends ConsumerWidget {
  final ShowModel? currentShow;

  const LivePlayerWidget({super.key, this.currentShow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackStateStreamProvider);
    final player = ref.watch(audioPlayerProvider);
    final isReconnecting = ref.watch(reconnectingProvider);
    final volume = ref.watch(volumeProvider);
    final streamUrlAsync = ref.watch(liveStreamUrlProvider);

    // Determine current stream URL
    final streamUrl = streamUrlAsync.valueOrNull ?? '';
    final noUrl = streamUrl.isEmpty;

    if (noUrl) {
      return Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(
            AppStrings.noStreamConfigured,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return playbackState.when(
      data: (state) {
        final isPlaying = state.playing;
        final isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;

        return Column(
          children: [
            WaveformWidget(isPlaying: isPlaying && !isLoading),
            const SizedBox(height: AppDimensions.p12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LIVE', style: AppTextStyles.mono),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('● LIVE', style: AppTextStyles.liveLabel),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            Row(
              children: [
                // Volume
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      final box = context.findRenderObject() as RenderBox;
                      final newVol = (volume + d.delta.dx / box.size.width)
                          .clamp(0.0, 1.0);
                      ref.read(volumeProvider.notifier).state = newVol;
                      player.setVolume(newVol);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          volume > 0.6
                              ? Icons.volume_up
                              : volume > 0.2
                                  ? Icons.volume_down
                                  : Icons.volume_mute,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: volume,
                          backgroundColor: AppColors.border2,
                          color: AppColors.amberGold,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.p16),
                // Play/Pause button
                GestureDetector(
                  onTap: () async {
                    if (isLoading) return;
                    if (isPlaying) {
                      await player.pause();
                    } else {
                      if (player.processingState == ProcessingState.idle ||
                          player.processingState == ProcessingState.completed) {
                        await player.setUrl(streamUrl);
                      }
                      await player.play();
                    }
                  },
                  child: Container(
                    width: AppDimensions.playerButtonLg,
                    height: AppDimensions.playerButtonLg,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isReconnecting || isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.appBackground,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.appBackground,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: AppDimensions.p16),
                // Share + notify
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          final title = currentShow?.title ?? 'Lion FM 91.1 MHz';
                          Share.share(
                            "I'm listening to $title on Lion FM 91.1 MHz! "
                            "Stream live at www.lionfm.online",
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          final user = ref.read(userProvider);
                          if (user.notifyShowAlerts) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "We'll notify you 10 minutes before "
                                  "${currentShow?.title ?? 'this show'} next week 🔔",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Enable show alerts in Settings to get reminders.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox(height: 120),
    );
  }
}
