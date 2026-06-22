import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/episode_model.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/podcast_provider.dart';

class LatestPodcastsWidget extends ConsumerWidget {
  const LatestPodcastsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestEpisodesProvider);

    return latest.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (episodes) {
        if (episodes.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.p16, 0, AppDimensions.p16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LATEST PODCASTS', style: AppTextStyles.label),
                  TextButton(
                    onPressed: () => context.go('/podcasts'),
                    child: const Text('See all →'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) =>
                      _EpisodeChip(episode: episodes[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EpisodeChip extends ConsumerWidget {
  final EpisodeModel episode;
  const _EpisodeChip({required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playingId = ref.watch(playingEpisodeProvider);
    final isPlaying = playingId == episode.id;
    final player = ref.watch(audioPlayerProvider);

    return GestureDetector(
      onTap: () async {
        if (isPlaying) {
          await player.pause();
        } else {
          ref.read(playingEpisodeProvider.notifier).state = episode.id;
          if (episode.audioUrl.isNotEmpty) {
            await player.setUrl(episode.audioUrl);
            await player.play();
          }
        }
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.lionGreen.withValues(alpha: 0.15)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(
            color: isPlaying ? AppColors.lionGreen : AppColors.border1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? AppColors.lionGreen
                        : AppColors.electricBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  episode.formattedDuration,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              episode.title,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              DateFormat('MMM d').format(episode.publishedAt),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
