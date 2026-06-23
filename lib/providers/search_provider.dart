import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/episode_model.dart';
import '../data/models/event_model.dart';
import '../data/models/news_model.dart';
import '../data/models/show_model.dart';
import 'events_provider.dart';
import 'news_provider.dart';
import 'podcast_provider.dart';
import 'schedule_provider.dart';

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

class GlobalSearchResults {
  final List<NewsModel> news;
  final List<EpisodeModel> episodes;
  final List<ShowModel> shows;
  final List<EventModel> events;

  const GlobalSearchResults({
    required this.news,
    required this.episodes,
    required this.shows,
    required this.events,
  });
}

final globalSearchProvider = FutureProvider<GlobalSearchResults>((ref) async {
  final query = ref.watch(globalSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) {
    return const GlobalSearchResults(news: [], episodes: [], shows: [], events: []);
  }

  final news = await ref.watch(newsItemsProvider.future);
  final episodes = await ref.watch(episodesProvider.future);
  final selectedDay = ref.watch(selectedDayProvider);
  final shows = await ref.watch(scheduledShowsProvider(selectedDay).future);
  final events = await ref.watch(eventsStreamProvider.future);

  bool has(String value) => value.toLowerCase().contains(query);

  return GlobalSearchResults(
    news: news.where((n) => has(n.headline) || has(n.summary)).toList(),
    episodes: episodes.where((e) => has(e.title) || has(e.showName) || has(e.description)).toList(),
    shows: shows.where((s) => has(s.title) || has(s.hostName) || has(s.description)).toList(),
    events: events.where((e) => has(e.title) || has(e.description)).toList(),
  );
});
