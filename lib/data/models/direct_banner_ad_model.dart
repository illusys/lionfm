class DirectBannerAd {
  final String id;
  final String imageUrl;
  final String targetUrl;
  final String advertiserName;
  final String placement;
  final DateTime expiresAt;

  const DirectBannerAd({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
    required this.advertiserName,
    required this.placement,
    required this.expiresAt,
  });
}
