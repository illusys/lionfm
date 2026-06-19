class EpisodeModel {
  final String id;
  final String showId;
  final String showName;
  final String title;
  final String description;
  final int durationMinutes;
  final DateTime publishedAt;
  final String audioUrl;
  final String? imageUrl;
  final String category;
  final bool isDownloaded;
  final int playbackPosition;

  const EpisodeModel({
    required this.id,
    required this.showId,
    required this.showName,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.publishedAt,
    required this.audioUrl,
    this.imageUrl,
    required this.category,
    this.isDownloaded = false,
    this.playbackPosition = 0,
  });

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${durationMinutes}m';
  }

  EpisodeModel copyWith({
    String? id,
    String? showId,
    String? showName,
    String? title,
    String? description,
    int? durationMinutes,
    DateTime? publishedAt,
    String? audioUrl,
    String? imageUrl,
    String? category,
    bool? isDownloaded,
    int? playbackPosition,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      showName: showName ?? this.showName,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      publishedAt: publishedAt ?? this.publishedAt,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      playbackPosition: playbackPosition ?? this.playbackPosition,
    );
  }

  factory EpisodeModel.fromJson(Map<String, dynamic> json) => EpisodeModel(
        id: json['id'] as String,
        showId: json['showId'] as String,
        showName: json['showName'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        durationMinutes: json['durationMinutes'] as int,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        audioUrl: json['audioUrl'] as String,
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String,
        isDownloaded: json['isDownloaded'] as bool? ?? false,
        playbackPosition: json['playbackPosition'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'showId': showId,
        'showName': showName,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'publishedAt': publishedAt.toIso8601String(),
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'category': category,
        'isDownloaded': isDownloaded,
        'playbackPosition': playbackPosition,
      };
}
