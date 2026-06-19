enum ShowCategory { news, health, tech, music, devotion, talkShow, general }

enum ShowStatus { live, upcoming, done }

class ShowModel {
  final String id;
  final String title;
  final String hostName;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek;
  final ShowCategory category;
  final List<String> tags;
  final String? imageUrl;
  final bool isRecurring;

  const ShowModel({
    required this.id,
    required this.title,
    required this.hostName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.category,
    this.tags = const [],
    this.imageUrl,
    this.isRecurring = true,
  });

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

  ShowModel copyWith({
    String? id,
    String? title,
    String? hostName,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? dayOfWeek,
    ShowCategory? category,
    List<String>? tags,
    String? imageUrl,
    bool? isRecurring,
  }) {
    return ShowModel(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  factory ShowModel.fromJson(Map<String, dynamic> json) => ShowModel(
        id: json['id'] as String,
        title: json['title'] as String,
        hostName: json['hostName'] as String,
        description: json['description'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        dayOfWeek: json['dayOfWeek'] as String,
        category: ShowCategory.values.byName(json['category'] as String),
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        imageUrl: json['imageUrl'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hostName': hostName,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'dayOfWeek': dayOfWeek,
        'category': category.name,
        'tags': tags,
        'imageUrl': imageUrl,
        'isRecurring': isRecurring,
      };
}
