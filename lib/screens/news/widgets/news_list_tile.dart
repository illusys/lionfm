import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/news_model.dart';

class NewsListTile extends StatelessWidget {
  final NewsModel news;

  const NewsListTile({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (news.sourceUrl != null) {
              await launchUrl(Uri.parse(news.sourceUrl!));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.p16,
              vertical: AppDimensions.p12,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.thumbnailNews,
                  height: AppDimensions.thumbnailNews,
                  decoration: BoxDecoration(
                    color: _categoryColor(news.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _categoryIcon(news.category),
                    color: _categoryColor(news.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.category.name.toUpperCase(),
                        style: AppTextStyles.categoryLabel,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        news.headline,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(_timeAgo(news.publishedAt),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16),
                      color: AppColors.textTertiary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Share.share(
                          '${news.headline} — via Lion FM 91.1 MHz · lionfm.unn.edu.ng',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Color _categoryColor(NewsCategory cat) => switch (cat) {
        NewsCategory.campus => AppColors.electricBlue,
        NewsCategory.academic => AppColors.amberGold,
        NewsCategory.sports => AppColors.emeraldGreen,
        NewsCategory.events => AppColors.broadcastOrange,
        NewsCategory.health => AppColors.signalTeal,
      };

  IconData _categoryIcon(NewsCategory cat) => switch (cat) {
        NewsCategory.campus => Icons.school,
        NewsCategory.academic => Icons.menu_book,
        NewsCategory.sports => Icons.sports_soccer,
        NewsCategory.events => Icons.event,
        NewsCategory.health => Icons.local_hospital,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
