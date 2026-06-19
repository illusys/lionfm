import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/show_model.dart';
import '../data/repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return MockScheduleRepository();
});

final selectedDayProvider = StateProvider<String>((ref) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[DateTime.now().weekday - 1];
});

final scheduledShowsProvider =
    FutureProvider.family<List<ShowModel>, String>((ref, dayOfWeek) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getShowsForDay(dayOfWeek);
});

final currentShowProvider = FutureProvider<ShowModel?>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getCurrentShow();
});

final upcomingShowsProvider = FutureProvider<List<ShowModel>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final today = days[DateTime.now().weekday - 1];
  final shows = await repo.getShowsForDay(today);
  final now = DateTime.now();
  return shows.where((s) => s.getStatus(now) == ShowStatus.upcoming).take(3).toList();
});
