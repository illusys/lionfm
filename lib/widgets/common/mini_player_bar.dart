import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/services/audio_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/schedule_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(currentAudioSourceProvider);
    final playbackState = ref.watch(playbackStateStreamProvider);
    final episode = ref.watch(currentEpisodeProvider);
    final adDurationSec = ref.watch(currentAdDurationProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        border: Border(top: BorderSide(color: AppColors.borderGreen, width: 1)),
      ),
      child: switch (source) {
        AudioSourceType.ad => _AdBar(durationSec: adDurationSec),
        AudioSourceType.podcast when episode != null =>
          _PodcastBar(episode: episode, playbackState: playbackState),
        _ => _LiveBar(playbackState: playbackState),
      },
    );
  }
}

// ─── Live radio bar ───────────────────────────────────────────────────────────

class _LiveBar extends ConsumerWidget {
  final AsyncValue<PlayerState> playbackState;
  const _LiveBar({required this.playbackState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentShow = ref.watch(currentShowProvider);

    return GestureDetector(
      onTap: () => context.go('/'),
      child: SizedBox(
        height: AppDimensions.miniPlayerHeight + 4,
        child: Column(
          children: [
            const LinearProgressIndicator(
              value: null,
              backgroundColor: AppColors.bg3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lionGreen),
              minHeight: 2,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16),
                child: Row(
                  children: [
                    // Artwork
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenTealGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.r8),
                      ),
                      alignment: Alignment.center,
                      child: Text('FM',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.bg0, fontSize: 12)),
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
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.liveRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('LIVE',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.liveRed)),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) =>
                            Text('Lion FM', style: AppTextStyles.body),
                      ),
                    ),
                    // Play/Pause
                    _PlayPauseButton(playbackState: playbackState),
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

// ─── Podcast bar ──────────────────────────────────────────────────────────────

class _PodcastBar extends ConsumerWidget {
  final dynamic episode;
  final AsyncValue<PlayerState> playbackState;
  const _PodcastBar({required this.episode, required this.playbackState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(durationStreamProvider).valueOrNull;
    final handler = ref.read(audioHandlerProvider);
    final streamUrl = ref.read(currentStreamUrlProvider);

    final progress = (duration != null && duration.inSeconds > 0)
        ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    String _fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
    }

    return SizedBox(
      height: 96,
      child: Column(
        children: [
          // Progress bar (tappable scrubber)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (duration == null || duration.inSeconds == 0) return;
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final x =
                  details.localPosition.dx.clamp(0.0, box.size.width);
              final frac = x / box.size.width;
              handler.seek(Duration(
                  seconds: (frac * duration.inSeconds).round()));
            },
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bg3,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.electricTeal),
                minHeight: 3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p12),
              child: Row(
                children: [
                  // Episode icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.r8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.headphones_rounded,
                        color: AppColors.electricTeal, size: 18),
                  ),
                  const SizedBox(width: AppDimensions.p8),
                  // Title + time
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.title as String,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          duration != null
                              ? '${_fmt(position)} / ${_fmt(duration)}'
                              : _fmt(position),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // Skip back 15s
                  _IconBtn(
                    icon: Icons.replay_rounded,
                    onTap: () => handler.seekBackward(),
                  ),
                  // Play/Pause
                  _PlayPauseButton(playbackState: playbackState),
                  // Skip forward 30s
                  _IconBtn(
                    icon: Icons.forward_30_rounded,
                    onTap: () => handler.seekForward(),
                  ),
                  // Back to Live
                  if (streamUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        await handler.playLiveRadio(streamUrl);
                        ref
                            .read(currentAudioSourceProvider.notifier)
                            .state = AudioSourceType.liveRadio;
                        ref
                            .read(currentEpisodeProvider.notifier)
                            .state = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.borderGreen),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.rFull),
                        ),
                        child: Text('LIVE',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.lionGreen)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ad bar ───────────────────────────────────────────────────────────────────

class _AdBar extends ConsumerWidget {
  final int durationSec;
  const _AdBar({required this.durationSec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(positionStreamProvider).valueOrNull ?? Duration.zero;
    final remaining =
        (durationSec - position.inSeconds).clamp(0, durationSec);
    final progress = durationSec > 0
        ? (position.inSeconds / durationSec).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      height: AppDimensions.miniPlayerHeight + 4,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bg3,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.warningGold),
            minHeight: 2,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p16),
              child: Row(
                children: [
                  const Icon(Icons.volume_up_rounded,
                      color: AppColors.warningGold, size: 18),
                  const SizedBox(width: AppDimensions.p12),
                  Expanded(
                    child: Text(
                      'Advertisement',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningGold.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.rFull),
                    ),
                    child: Text('Ad · ${remaining}s',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.warningGold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _PlayPauseButton extends ConsumerWidget {
  final AsyncValue<PlayerState> playbackState;
  const _PlayPauseButton({required this.playbackState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    return playbackState.when(
      data: (state) {
        final isPlaying = state.playing;
        final isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        return GestureDetector(
          onTap: () => isPlaying ? handler.pause() : handler.play(),
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
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.bg0,
                    size: 20,
                  ),
          ),
        );
      },
      loading: () => const SizedBox(width: 36, height: 36),
      error: (_, __) => const SizedBox(width: 36, height: 36),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}
