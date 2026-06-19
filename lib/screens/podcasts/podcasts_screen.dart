import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/podcast_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import 'widgets/category_chips.dart';
import 'widgets/episode_card.dart';
import 'widgets/podcast_search_bar.dart';

class PodcastsScreen extends ConsumerWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredEpisodesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Podcasts')),
      body: Column(
        children: [
          const PodcastSearchBar(),
          const CategoryChips(),
          const SizedBox(height: AppDimensions.p8),
          Expanded(
            child: filtered.when(
              data: (episodes) {
                if (episodes.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.headphones,
                    title: 'No episodes found',
                    subtitle: 'Try a different search or category',
                  );
                }
                return ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (_, i) => EpisodeCard(episode: episodes[i]),
                );
              },
              loading: () => ListView(
                children: List.generate(
                    4, (_) => const EpisodeCardShimmer()),
              ),
              error: (e, _) => ErrorStateWidget(
                message: 'Could not load episodes',
                onRetry: () => ref.refresh(episodesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
