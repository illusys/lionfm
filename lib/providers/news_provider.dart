import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/news_model.dart';
import '../data/repositories/news_repository.dart';
import 'current_station_provider.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return FirestoreNewsRepository(
      stationId: ref.watch(currentStationIdProvider));
});

final newsItemsProvider = FutureProvider<List<NewsModel>>((ref) async {
  return ref.watch(newsRepositoryProvider).getNews();
});

final featuredNewsProvider = Provider<AsyncValue<NewsModel?>>((ref) {
  return ref.watch(newsItemsProvider).whenData(
        (list) => list.where((n) => n.isFeatured).firstOrNull,
      );
});

final newsCategoryProvider = StateProvider<String>((ref) => 'all');

final filteredNewsProvider = Provider<AsyncValue<List<NewsModel>>>((ref) {
  final news = ref.watch(newsItemsProvider);
  final category = ref.watch(newsCategoryProvider);
  return news.whenData((list) {
    if (category == 'all') return list;
    return list.where((n) => n.category.name == category).toList();
  });
});
