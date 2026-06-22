import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/show_model.dart';
import '../../../data/services/audio_service.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/user_provider.dart';
import 'waveform_widget.dart';

class LivePlayerWidget extends ConsumerWidget {
  final ShowModel? currentShow;

  const LivePlayerWidget({super.key, this.currentShow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackStateStreamProvider);
    final handler = ref.read(audioHandlerProvider);
    final isReconnecting = ref.watch(reconnectingProvider);
    final volume = ref.watch(volumeProvider);
    final streamUrlAsync = ref.watch(liveStreamUrlProvider);

    final streamUrl = streamUrlAsync.valueOrNull ?? '';
    final noUrl = streamUrl.isEmpty;

    if (noUrl) {
      return Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 32),
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
                Row(children: [
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
                ]),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            Row(
              children: [
                // Volume slider
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final muted = volume == 0.0;
                          final newVol = muted ? 0.75 : 0.0;
                          ref.read(volumeProvider.notifier).state = newVol;
                          handler.setVolume(newVol);
                        },
                        child: Icon(
                          volume > 0.6
                              ? Icons.volume_up_rounded
                              : volume > 0.0
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_off_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                          activeTrackColor: AppColors.lionGold,
                          inactiveTrackColor: AppColors.border2,
                          thumbColor: AppColors.lionGold,
                          overlayColor:
                              AppColors.lionGold.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) {
                            ref.read(volumeProvider.notifier).state = v;
                            handler.setVolume(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.p16),
                // Pulsing play button (76px, gold→green gradient)
                _PulsingPlayButton(
                  isPlaying: isPlaying,
                  isLoading: isReconnecting || isLoading,
                  onTap: () async {
                    if (isLoading) return;
                    final source = ref.read(currentAudioSourceProvider);
                    if (isPlaying) {
                      await handler.pause();
                    } else {
                      if (source == AudioSourceType.podcast) {
                        await handler.play();
                      } else {
                        await handler.playLiveRadio(streamUrl);
                        ref
                            .read(currentAudioSourceProvider.notifier)
                            .state = AudioSourceType.liveRadio;
                        ref.read(currentEpisodeProvider.notifier).state = null;
                      }
                    }
                  },
                ),
                const SizedBox(width: AppDimensions.p16),
                // Share + notify with 44×44 tap targets
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.share, size: 26),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            final title =
                                currentShow?.title ?? 'Lion FM 91.1 MHz';
                            Share.share(
                              "I'm listening to $title on Lion FM 91.1 MHz! "
                              "Stream live at www.lionfm.online",
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.notifications_none, size: 26),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            final user = ref.read(userProvider);
                            if (user.notifyShowAlerts) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "We'll notify you before "
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

// ─── Pulsing play/pause button ────────────────────────────────────────────────

class _PulsingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PulsingPlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: widget.isPlaying ? _scale.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC89A29), Color(0xFF1E9B43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x441E9B43),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
}
