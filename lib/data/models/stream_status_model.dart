class StreamStatusModel {
  final bool isLive;
  final int listenerCount;
  final String? currentShowId;
  final String currentShowTitle;
  final String currentHostName;
  final int streamBitrate;
  final String streamUrl;
  final DateTime lastCheckedAt;

  const StreamStatusModel({
    required this.isLive,
    required this.listenerCount,
    this.currentShowId,
    required this.currentShowTitle,
    required this.currentHostName,
    required this.streamBitrate,
    required this.streamUrl,
    required this.lastCheckedAt,
  });

  bool get isHealthy =>
      isLive &&
      streamUrl.isNotEmpty &&
      DateTime.now().difference(lastCheckedAt).inMinutes < 2;

  StreamStatusModel copyWith({
    bool? isLive,
    int? listenerCount,
    String? currentShowId,
    String? currentShowTitle,
    String? currentHostName,
    int? streamBitrate,
    String? streamUrl,
    DateTime? lastCheckedAt,
  }) {
    return StreamStatusModel(
      isLive: isLive ?? this.isLive,
      listenerCount: listenerCount ?? this.listenerCount,
      currentShowId: currentShowId ?? this.currentShowId,
      currentShowTitle: currentShowTitle ?? this.currentShowTitle,
      currentHostName: currentHostName ?? this.currentHostName,
      streamBitrate: streamBitrate ?? this.streamBitrate,
      streamUrl: streamUrl ?? this.streamUrl,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  factory StreamStatusModel.fromJson(Map<String, dynamic> json) =>
      StreamStatusModel(
        isLive: json['isLive'] as bool,
        listenerCount: json['listenerCount'] as int,
        currentShowId: json['currentShowId'] as String?,
        currentShowTitle: json['currentShowTitle'] as String,
        currentHostName: json['currentHostName'] as String,
        streamBitrate: json['streamBitrate'] as int,
        streamUrl: json['streamUrl'] as String,
        lastCheckedAt: DateTime.parse(json['lastCheckedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'isLive': isLive,
        'listenerCount': listenerCount,
        'currentShowId': currentShowId,
        'currentShowTitle': currentShowTitle,
        'currentHostName': currentHostName,
        'streamBitrate': streamBitrate,
        'streamUrl': streamUrl,
        'lastCheckedAt': lastCheckedAt.toIso8601String(),
      };
}
