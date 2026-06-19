import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_model.freezed.dart';
part 'news_model.g.dart';

enum NewsCategory { campus, academic, sports, events, health }

@freezed
class NewsModel with _$NewsModel {
  const factory NewsModel({
    required String id,
    required String headline,
    required String summary,
    required NewsCategory category,
    required DateTime publishedAt,
    String? imageUrl,
    String? sourceUrl,
    @Default(false) bool isFeatured,
    @Default(3) int readTimeMinutes,
  }) = _NewsModel;

  factory NewsModel.fromJson(Map<String, dynamic> json) =>
      _$NewsModelFromJson(json);
}
