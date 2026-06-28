import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/direct_banner_ad_model.dart';
import '../../providers/current_station_provider.dart';
import '../../providers/user_provider.dart';

final _activeAdsProvider =
    StreamProvider.family<List<DirectBannerAd>, String>((ref, placement) {
  final stationId = ref.watch(currentStationIdProvider);
  final now = Timestamp.now();
  return FirebaseFirestore.instance
      .collection('ads')
      .where('stationId', isEqualTo: stationId)
      .where('placement', isEqualTo: placement)
      .where('isActive', isEqualTo: true)
      .where('endDate', isGreaterThan: now)
      .snapshots()
      .map((snap) {
    final nowDt = DateTime.now();
    return snap.docs
        .map((d) => DirectBannerAd.fromFirestore(d))
        .where((ad) => ad.startDate.isBefore(nowDt))
        .toList();
  });
});

class DirectBannerWidget extends ConsumerWidget {
  final String placement;
  final double? height;
  const DirectBannerWidget(
      {super.key, required this.placement, this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user.isPremium) return const SizedBox.shrink();

    final adsAsync = ref.watch(_activeAdsProvider(placement));

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();
        final ad = ads.first;
        final adHeight = height ?? _heightFor(ad.format);
        return _BannerAdTile(ad: ad, adHeight: adHeight);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  double _heightFor(IabAdFormat f) {
    switch (f) {
      case IabAdFormat.mobileLeaderboard:
        return 50;
      case IabAdFormat.largeMobileBanner:
        return 100;
      case IabAdFormat.mediumRectangle:
        return 250;
      case IabAdFormat.mobileInterstitial:
        return 480;
      case IabAdFormat.billboard:
        return 250;
    }
  }
}

class _BannerAdTile extends StatelessWidget {
  final DirectBannerAd ad;
  final double adHeight;
  const _BannerAdTile({required this.ad, required this.adHeight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: GestureDetector(
        onTap: () async {
          // Track click
          FirebaseFirestore.instance.collection('ads').doc(ad.id).update({
            'clicks': FieldValue.increment(1),
          });
          final uri = Uri.tryParse(ad.clickUrl);
          if (uri != null) await launchUrl(uri);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: adHeight,
                    child: CachedNetworkImage(
                      imageUrl: ad.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(
                        height: adHeight,
                        color: AppColors.bg2,
                        alignment: Alignment.center,
                        child: Text(ad.advertiserName,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: adHeight,
                        color: AppColors.bg2,
                        alignment: Alignment.center,
                        child: Text(ad.advertiserName,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('AD',
                    style: TextStyle(
                        fontSize: 9, color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
