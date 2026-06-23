import 'package:hive_flutter/hive_flutter.dart';

class OfflineEpisodeMetadata {
  final String id;
  final String title;
  final String localPath;
  final DateTime downloadedAt;

  const OfflineEpisodeMetadata({
    required this.id,
    required this.title,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineEpisodeMetadata.fromJson(Map<dynamic, dynamic> json) =>
      OfflineEpisodeMetadata(
        id: json['id'] as String,
        title: json['title'] as String,
        localPath: json['localPath'] as String,
        downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class OfflineMetadataRepository {
  static const _boxName = 'offline_episode_metadata';

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<void> save(OfflineEpisodeMetadata episode) async {
    final box = await _box();
    await box.put(episode.id, episode.toJson());
  }

  Future<List<OfflineEpisodeMetadata>> all() async {
    final box = await _box();
    return box.values
        .whereType<Map>()
        .map(OfflineEpisodeMetadata.fromJson)
        .toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
  }

  Future<void> remove(String episodeId) async {
    final box = await _box();
    await box.delete(episodeId);
  }
}
