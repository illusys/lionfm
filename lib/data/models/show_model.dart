import 'package:freezed_annotation/freezed_annotation.dart';

part 'show_model.freezed.dart';
part 'show_model.g.dart';

enum ShowCategory {
  news,
  health,
  tech,
  music,
  devotion,
  talkShow,
  general,
}

enum ShowStatus { live, upcoming, done }

@freezed
class ShowModel with _$ShowModel {
  const ShowModel._();

  const factory ShowModel({
    required String id,
    required String title,
    required String hostName,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String dayOfWeek,
    required ShowCategory category,
    @Default([]) List<String> tags,
    String? imageUrl,
    @Default(true) bool isRecurring,
  }) = _ShowModel;

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  ShowStatus getStatus(DateTime now) {
    if (now.isAfter(startTime) && now.isBefore(endTime)) return ShowStatus.live;
    if (now.isBefore(startTime)) return ShowStatus.upcoming;
    return ShowStatus.done;
  }

  String get timeRange {
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $period';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  factory ShowModel.fromJson(Map<String, dynamic> json) => _$ShowModelFromJson(json);
}
