import 'package:cloud_firestore/cloud_firestore.dart';

enum IabAdFormat {
  mobileLeaderboard,    // 320x50
  mediumRectangle,      // 300x250
  largeMobileBanner,    // 320x100
  mobileInterstitial,   // 320x480
  billboard,            // 970x250 (web only)
}

extension IabAdFormatExt on IabAdFormat {
  String get label {
    switch (this) {
      case IabAdFormat.mobileLeaderboard:
        return 'Mobile Leaderboard (320×50)';
      case IabAdFormat.mediumRectangle:
        return 'Medium Rectangle (300×250)';
      case IabAdFormat.largeMobileBanner:
        return 'Large Mobile Banner (320×100)';
      case IabAdFormat.mobileInterstitial:
        return 'Mobile Interstitial (320×480)';
      case IabAdFormat.billboard:
        return 'Billboard (970×250)';
    }
  }

  double get width {
    switch (this) {
      case IabAdFormat.mobileLeaderboard:
        return 320;
      case IabAdFormat.mediumRectangle:
        return 300;
      case IabAdFormat.largeMobileBanner:
        return 320;
      case IabAdFormat.mobileInterstitial:
        return 320;
      case IabAdFormat.billboard:
        return 970;
    }
  }

  double get height {
    switch (this) {
      case IabAdFormat.mobileLeaderboard:
        return 50;
      case IabAdFormat.mediumRectangle:
        return 250;
      case IabAdFormat.largeMobileBanner:
        return 100;
      case IabAdFormat.mobileInterstitial:
        return 480;
      case IabAdFormat.billboard:
        return 250;
    }
  }

  double get aspectRatio => width / height;

  String get firestoreKey => name;
}

IabAdFormat iabAdFormatFromString(String? s) {
  for (final v in IabAdFormat.values) {
    if (v.name == s) return v;
  }
  return IabAdFormat.mobileLeaderboard;
}

class DirectBannerAd {
  final String id;
  final String advertiserName;
  final IabAdFormat format;
  final String imageUrl;
  final String clickUrl;
  final String placement;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int impressions;
  final int clicks;

  const DirectBannerAd({
    required this.id,
    required this.advertiserName,
    required this.format,
    required this.imageUrl,
    required this.clickUrl,
    required this.placement,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.impressions = 0,
    this.clicks = 0,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  String get status {
    final now = DateTime.now();
    if (!isActive) return 'inactive';
    if (now.isBefore(startDate)) return 'scheduled';
    if (now.isAfter(endDate)) return 'expired';
    return 'active';
  }

  factory DirectBannerAd.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DirectBannerAd(
      id: doc.id,
      advertiserName: d['advertiser'] as String? ?? '',
      format: iabAdFormatFromString(d['format'] as String?),
      imageUrl: d['imageUrl'] as String? ?? '',
      clickUrl: d['clickUrl'] as String? ?? '',
      placement: d['placement'] as String? ?? '',
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      isActive: d['isActive'] as bool? ?? true,
      impressions: d['impressions'] as int? ?? 0,
      clicks: d['clicks'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'advertiser': advertiserName,
        'format': format.firestoreKey,
        'size': '${format.width.toInt()}x${format.height.toInt()}',
        'imageUrl': imageUrl,
        'clickUrl': clickUrl,
        'placement': placement,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'impressions': impressions,
        'clicks': clicks,
      };

  // Legacy support
  String get targetUrl => clickUrl;
  DateTime get expiresAt => endDate;
}
