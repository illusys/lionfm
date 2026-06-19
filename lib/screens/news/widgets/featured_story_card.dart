import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/news_model.dart';

class FeaturedStoryCard extends StatelessWidget {
  final NewsModel news;

  const FeaturedStoryCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = news.sourceUrl;
        if (url != null) await launchUrl(Uri.parse(url));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppDimensions.p16,
          AppDimensions.p12,
          AppDimensions.p16,
          AppDimensions.p8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Container(
              height: AppDimensions.featuredCardHeight,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              alignment: Alignment.center,
              child: const Text('📌', style: TextStyle(fontSize: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📌 FEATURED · CAMPUS',
                    style: AppTextStyles.categoryLabel,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.headline,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lion FM News Desk · ${_timeAgo(news.publishedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
