enum NewsCategory { campus, academic, sports, events, health }

class NewsModel {
  final String id;
  final String headline;
  final String summary;
  final NewsCategory category;
  final DateTime publishedAt;
  final String? imageUrl;
  final String? sourceUrl;
  final bool isFeatured;
  final int readTimeMinutes;

  const NewsModel({
    required this.id,
    required this.headline,
    required this.summary,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.sourceUrl,
    this.isFeatured = false,
    this.readTimeMinutes = 3,
  });

  NewsModel copyWith({
    String? id,
    String? headline,
    String? summary,
    NewsCategory? category,
    DateTime? publishedAt,
    String? imageUrl,
    String? sourceUrl,
    bool? isFeatured,
    int? readTimeMinutes,
  }) {
    return NewsModel(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
    );
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) => NewsModel(
        id: json['id'] as String,
        headline: json['headline'] as String,
        summary: json['summary'] as String,
        category: NewsCategory.values.byName(json['category'] as String),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        imageUrl: json['imageUrl'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
        isFeatured: json['isFeatured'] as bool? ?? false,
        readTimeMinutes: json['readTimeMinutes'] as int? ?? 3,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'headline': headline,
        'summary': summary,
        'category': category.name,
        'publishedAt': publishedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'sourceUrl': sourceUrl,
        'isFeatured': isFeatured,
        'readTimeMinutes': readTimeMinutes,
      };
}
