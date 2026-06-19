import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode_model.freezed.dart';
part 'episode_model.g.dart';

@freezed
class EpisodeModel with _$EpisodeModel {
  const EpisodeModel._();

  const factory EpisodeModel({
    required String id,
    required String showId,
    required String showName,
    required String title,
    required String description,
    required int durationMinutes,
    required DateTime publishedAt,
    required String audioUrl,
    String? imageUrl,
    required String category,
    @Default(false) bool isDownloaded,
    @Default(0) int playbackPosition,
  }) = _EpisodeModel;

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${durationMinutes}m';
  }

  factory EpisodeModel.fromJson(Map<String, dynamic> json) =>
      _$EpisodeModelFromJson(json);
}
