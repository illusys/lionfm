import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/station_repository.dart';
import '../models/station.dart';

final stationsRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository();
});

/// Watch a single station document by stationId (= slug, e.g. "lion").
final stationProvider =
    StreamProvider.family<Station, String>((ref, stationId) {
  return ref.watch(stationsRepositoryProvider).watchStation(stationId);
});

/// All stations regardless of isActive — platform owner view.
final allStationsProvider = StreamProvider<List<Station>>((ref) {
  return ref.watch(stationsRepositoryProvider).watchAll();
});

/// All stations with isActive == true, ordered by createdAt.
final allActiveStationsProvider = StreamProvider<List<Station>>((ref) {
  return ref.watch(stationsRepositoryProvider).watchAllActive();
});

/// Stations marked isFeatured == true (for the public directory).
final featuredStationsProvider = StreamProvider<List<Station>>((ref) {
  return ref.watch(stationsRepositoryProvider).watchFeatured();
});
