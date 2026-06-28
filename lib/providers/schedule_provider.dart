import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/show_model.dart';
import '../data/repositories/schedule_repository.dart';
import 'current_station_provider.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return FirestoreScheduleRepository(
      stationId: ref.watch(currentStationIdProvider));
});

final selectedDayProvider = StateProvider<String>((ref) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return days[DateTime.now().weekday - 1];
});

// Real-time stream from Firestore
final scheduledShowsStreamProvider =
    StreamProvider.family<List<ShowModel>, String>((ref, dayOfWeek) {
  final stationId = ref.watch(currentStationIdProvider);
  return watchShowsForDay(dayOfWeek, stationId: stationId);
});

// FutureProvider for compatibility with schedule screen
final scheduledShowsProvider =
    FutureProvider.family<List<ShowModel>, String>((ref, dayOfWeek) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getShowsForDay(dayOfWeek);
});

// Polls every 30s for the current on-air show
final currentShowProvider = StreamProvider<ShowModel?>((ref) async* {
  final repo = ref.read(scheduleRepositoryProvider);
  while (true) {
    try {
      yield await repo.getCurrentShow();
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

final upcomingShowsProvider = FutureProvider<List<ShowModel>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final today = days[DateTime.now().weekday - 1];
  final shows = await repo.getShowsForDay(today);
  final now = DateTime.now();
  return shows
      .where((s) => s.getStatus(now) == ShowStatus.upcoming)
      .take(3)
      .toList();
});
