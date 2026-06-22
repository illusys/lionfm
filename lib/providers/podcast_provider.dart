import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/episode_model.dart';
import '../data/repositories/podcast_repository.dart';

final podcastRepositoryProvider = Provider<PodcastRepository>((ref) {
  return FirestoreEpisodeRepository();
});

final episodesProvider = FutureProvider<List<EpisodeModel>>((ref) async {
  return ref.watch(podcastRepositoryProvider).getEpisodes();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final podcastCategoryProvider = StateProvider<String>((ref) => 'all');

final filteredEpisodesProvider =
    Provider<AsyncValue<List<EpisodeModel>>>((ref) {
  final episodes = ref.watch(episodesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(podcastCategoryProvider);

  return episodes.whenData((list) {
    var filtered = list;
    if (category != 'all') {
      filtered = filtered.where((e) => e.category == category).toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(query) ||
              e.showName.toLowerCase().contains(query))
          .toList();
    }
    return filtered;
  });
});

// Latest 4 episodes for the home page preview
final latestEpisodesProvider = FutureProvider<List<EpisodeModel>>((ref) async {
  final all = await ref.watch(episodesProvider.future);
  return all.take(4).toList();
});

final downloadedEpisodesProvider = StateProvider<Set<String>>((ref) => {});

final playingEpisodeProvider = StateProvider<String?>((ref) => null);
