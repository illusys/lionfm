import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/show_model.dart';

abstract class ScheduleRepository {
  Future<List<ShowModel>> getShowsForDay(String dayOfWeek);
  Future<ShowModel?> getCurrentShow();
}

class FirestoreScheduleRepository implements ScheduleRepository {
  final String stationId;
  FirestoreScheduleRepository({required this.stationId});

  static const _dayCodeMap = {
    'Monday': 'mon',
    'Tuesday': 'tue',
    'Wednesday': 'wed',
    'Thursday': 'thu',
    'Friday': 'fri',
    'Saturday': 'sat',
    'Sunday': 'sun',
  };

  @override
  Future<List<ShowModel>> getShowsForDay(String dayOfWeek) async {
    final dayCode = _dayCodeMap[dayOfWeek] ?? dayOfWeek.toLowerCase().substring(0, 3);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('shows')
          .where('stationId', isEqualTo: stationId)
          .where('isActive', isEqualTo: true)
          .get();

      final shows = snap.docs
          .where((doc) {
            final days = doc.data()['days'] as List<dynamic>? ?? [];
            return days.contains(dayCode);
          })
          .map((doc) => _fromFirestore(doc, dayOfWeek))
          .where((s) => s != null)
          .cast<ShowModel>()
          .toList();

      shows.sort((a, b) => a.startTime.compareTo(b.startTime));
      return shows;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ShowModel?> getCurrentShow() async {
    final now = DateTime.now();
    final dayName = _dayName(now.weekday);
    final shows = await getShowsForDay(dayName);
    for (final s in shows) {
      if (s.getStatus(now) == ShowStatus.live) return s;
    }
    return null;
  }

  ShowModel? _fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc, String dayOfWeek) {
    try {
      final d = doc.data();
      final startStr = d['startTime'] as String? ?? '00:00';
      final endStr = d['endTime'] as String? ?? '00:00';
      final now = DateTime.now();

      final start = _parseTime(startStr, now);
      final end = _parseTime(endStr, now);
      final categoryStr = (d['category'] as String? ?? 'music').toLowerCase();

      return ShowModel(
        id: doc.id,
        title: d['title'] as String? ?? '',
        hostName: d['host'] as String? ?? '',
        description: d['description'] as String? ?? '',
        startTime: start,
        endTime: end,
        dayOfWeek: dayOfWeek,
        category: _parseCategory(categoryStr),
        tags: (d['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        imageUrl: d['imageUrl'] as String?,
        isRecurring: d['isRecurring'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime _parseTime(String timeStr, DateTime base) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  ShowCategory _parseCategory(String s) {
    switch (s) {
      case 'news':
        return ShowCategory.news;
      case 'health':
        return ShowCategory.health;
      case 'tech':
        return ShowCategory.tech;
      case 'music':
        return ShowCategory.music;
      case 'devotion':
        return ShowCategory.devotion;
      case 'talk':
      case 'talkshow':
        return ShowCategory.talkShow;
      default:
        return ShowCategory.general;
    }
  }

  String _dayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

// Stream-based variant for reactive listeners
Stream<List<ShowModel>> watchShowsForDay(String dayOfWeek,
    {required String stationId}) {
  const dayCodeMap = {
    'Monday': 'mon',
    'Tuesday': 'tue',
    'Wednesday': 'wed',
    'Thursday': 'thu',
    'Friday': 'fri',
    'Saturday': 'sat',
    'Sunday': 'sun',
  };
  final dayCode =
      dayCodeMap[dayOfWeek] ?? dayOfWeek.toLowerCase().substring(0, 3);

  return FirebaseFirestore.instance
      .collection('shows')
      .where('stationId', isEqualTo: stationId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) {
    final now = DateTime.now();
    final shows = snap.docs
        .where((doc) {
          final days = doc.data()['days'] as List<dynamic>? ?? [];
          return days.contains(dayCode);
        })
        .map((doc) {
          try {
            final d = doc.data();
            final start = _parseTimeStatic(d['startTime'] as String? ?? '00:00', now);
            final end = _parseTimeStatic(d['endTime'] as String? ?? '00:00', now);
            return ShowModel(
              id: doc.id,
              title: d['title'] as String? ?? '',
              hostName: d['host'] as String? ?? '',
              description: d['description'] as String? ?? '',
              startTime: start,
              endTime: end,
              dayOfWeek: dayOfWeek,
              category: _parseCategoryStatic(
                  (d['category'] as String? ?? 'music').toLowerCase()),
              tags: (d['tags'] as List<dynamic>?)?.cast<String>() ?? [],
              imageUrl: d['imageUrl'] as String?,
              isRecurring: d['isRecurring'] as bool? ?? true,
            );
          } catch (_) {
            return null;
          }
        })
        .where((s) => s != null)
        .cast<ShowModel>()
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return shows;
  });
}

DateTime _parseTimeStatic(String timeStr, DateTime base) {
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(base.year, base.month, base.day, hour, minute);
}

ShowCategory _parseCategoryStatic(String s) {
  switch (s) {
    case 'news':
      return ShowCategory.news;
    case 'health':
      return ShowCategory.health;
    case 'tech':
      return ShowCategory.tech;
    case 'music':
      return ShowCategory.music;
    case 'devotion':
      return ShowCategory.devotion;
    case 'talk':
    case 'talkshow':
      return ShowCategory.talkShow;
    default:
      return ShowCategory.general;
  }
}

class MockScheduleRepository implements ScheduleRepository {
  @override
  Future<List<ShowModel>> getShowsForDay(String dayOfWeek) async => [];

  @override
  Future<ShowModel?> getCurrentShow() async => null;
}
