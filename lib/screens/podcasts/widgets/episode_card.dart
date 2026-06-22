import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../providers/audio_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/podcast_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/common/login_prompt_sheet.dart';

class EpisodeCard extends ConsumerWidget {
  final EpisodeModel episode;
  const EpisodeCard({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEpisode = ref.watch(currentEpisodeProvider);
    final source = ref.watch(currentAudioSourceProvider);
    final playbackState = ref.watch(playbackStateStreamProvider);
    final handler = ref.read(audioHandlerProvider);
    final isThisPlaying = source == AudioSourceType.podcast &&
        currentEpisode?.id == episode.id;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: isThisPlaying
              ? AppColors.electricBlue.withValues(alpha: 0.5)
              : AppColors.border1,
        ),
      ),
      child: Row(
        children: [
          _Thumbnail(episode: episode),
          const SizedBox(width: AppDimensions.p12),
          Expanded(child: _Info(episode: episode)),
          const SizedBox(width: 8),
          playbackState.when(
            data: (state) => _PlayButton(
              episode: episode,
              isThisPlaying: isThisPlaying,
              isPlaying: state.playing,
              isLoading: isThisPlaying &&
                  (state.processingState == ProcessingState.loading ||
                      state.processingState == ProcessingState.buffering),
              onTap: () async {
                if (isThisPlaying && state.playing) {
                  await handler.pause();
                } else {
                  final user = ref.read(userProvider);
                  await handler.playPodcast(
                    episode,
                    isPremium: user.isPremium,
                  );
                  await AnalyticsService.logEpisodePlay(
                    episodeId: episode.id,
                    title: episode.title,
                  );
                }
              },
            ),
            loading: () => const SizedBox(width: 36, height: 36),
            error: (_, __) => const SizedBox(width: 36, height: 36),
          ),
          const SizedBox(width: 6),
          if (!kIsWeb) _DownloadButton(episode: episode),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final EpisodeModel episode;
  const _Thumbnail({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 16),
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

class _Info extends StatelessWidget {
  final EpisodeModel episode;
  const _Info({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(episode.showName.toUpperCase(), style: AppTextStyles.categoryLabel),
        const SizedBox(height: 2),
        Text(episode.title,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Text(
          '${episode.formattedDuration} · '
          '${DateFormat('MMM d').format(episode.publishedAt)}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final EpisodeModel episode;
  final bool isThisPlaying;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  const _PlayButton({
    required this.episode,
    required this.isThisPlaying,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isThisPlaying ? AppColors.amberGold : AppColors.electricBlue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(
                isThisPlaying && isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final EpisodeModel episode;
  const _DownloadButton({required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadedEpisodesProvider);
    final isDone = downloads.contains(episode.id);

    return GestureDetector(
      onTap: () => _handleTap(context, ref, isDone),
      child: Container(
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
          color: isDone ? AppColors.successGreen : AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _handleTap(
      BuildContext context, WidgetRef ref, bool isDone) async {
    final isGuest = ref.read(isGuestModeProvider);
    final isSignedIn = ref.read(authStateProvider).valueOrNull != null;
    if (isGuest && !isSignedIn) {
      await LoginPromptSheet.show(context,
          reason: 'Sign in to download episodes for offline listening.');
      return;
    }
    if (isDone || episode.audioUrl.isEmpty) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Downloading: ${episode.title}…')));

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safe = episode.id.replaceAll(RegExp(r'[^\w]'), '_');
      final filePath = '${dir.path}/$safe.mp3';

      await Dio().download(episode.audioUrl, filePath);

      ref.read(downloadedEpisodesProvider.notifier).state = {
        ...ref.read(downloadedEpisodesProvider),
        episode.id,
      };

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Downloaded: ${episode.title}'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }
}
