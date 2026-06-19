import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/episode_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/podcast_provider.dart';
import '../../../widgets/common/login_prompt_sheet.dart';

class EpisodeCard extends ConsumerWidget {
  final EpisodeModel episode;

  const EpisodeCard({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playingId = ref.watch(playingEpisodeProvider);
    final playbackState = ref.watch(playbackStateStreamProvider);
    final player = ref.watch(audioPlayerProvider);
    final isThisPlaying = playingId == episode.id;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: isThisPlaying ? AppColors.electricBlue.withOpacity(0.5) : AppColors.border1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: AppDimensions.thumbnailEpisode,
            height: AppDimensions.thumbnailEpisode,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_categoryColor(episode.category), AppColors.surface3],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.r10),
            ),
            alignment: Alignment.center,
            child: Text(
              episode.showName.substring(0, 2).toUpperCase(),
              style: AppTextStyles.h3.copyWith(
                  color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.showName.toUpperCase(),
                  style: AppTextStyles.categoryLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  episode.title,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${episode.formattedDuration} · ${DateFormat('MMM d').format(episode.publishedAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Play button
          playbackState.when(
            data: (state) {
              final isLoading = isThisPlaying &&
                  (state.processingState.name == 'loading' ||
                      state.processingState.name == 'buffering');
              return GestureDetector(
                onTap: () async {
                  if (isThisPlaying && state.playing) {
                    await player.pause();
                  } else {
                    ref.read(playingEpisodeProvider.notifier).state = episode.id;
                    await player.setUrl(episode.audioUrl);
                    await player.play();
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isThisPlaying
                        ? AppColors.amberGold
                        : AppColors.electricBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isThisPlaying && state.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              );
            },
            loading: () => const SizedBox(width: 36, height: 36),
            error: (_, __) => const SizedBox(width: 36, height: 36),
          ),
          const SizedBox(width: 6),
          // Download button
          GestureDetector(
            onTap: () async {
              final isGuest = ref.read(isGuestModeProvider);
              final isSignedIn = ref.read(authStateProvider).valueOrNull != null;
              if (isGuest && !isSignedIn) {
                await LoginPromptSheet.show(
                  context,
                  reason: 'Sign in to download episodes for offline listening.',
                );
                return;
              }
              final downloads = ref.read(downloadedEpisodesProvider);
              ref.read(downloadedEpisodesProvider.notifier).state = {
                ...downloads,
                episode.id,
              };
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Downloaded: ${episode.title}')),
              );
            },
            child: Consumer(builder: (_, ref, __) {
              final downloads = ref.watch(downloadedEpisodesProvider);
              final isDone = downloads.contains(episode.id);
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDone ? Icons.check : Icons.download_outlined,
                  size: 16,
                  color: isDone
                      ? AppColors.successGreen
                      : AppColors.textSecondary,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    return switch (cat) {
      'health' => AppColors.emeraldGreen,
      'tech' => AppColors.electricBlue,
      'music' => AppColors.broadcastOrange,
      'news' => AppColors.amberGold,
      _ => AppColors.signalTeal,
    };
  }
}
