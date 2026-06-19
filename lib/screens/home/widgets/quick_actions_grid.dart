import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.p16,
        vertical: AppDimensions.p16,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppDimensions.p12,
        mainAxisSpacing: AppDimensions.p12,
        childAspectRatio: 1.6,
        children: const [
          _QuickActionCard(
            icon: Icons.radio,
            title: 'Podcasts',
            subtitle: AppStrings.latestEpisodes,
            color: AppColors.electricBlue,
            route: '/podcasts',
          ),
          _QuickActionCard(
            icon: Icons.calendar_today,
            title: 'Schedule',
            subtitle: AppStrings.todaysShows,
            color: AppColors.signalTeal,
            route: '/schedule',
          ),
          _QuickActionCard(
            icon: Icons.music_note,
            title: 'Request',
            subtitle: AppStrings.dedicateASong,
            color: AppColors.amberGold,
            route: '/requests',
          ),
          _QuickActionCard(
            icon: Icons.article,
            title: 'News',
            subtitle: AppStrings.campusUpdates,
            color: AppColors.broadcastOrange,
            route: '/news',
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.p12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: AppDimensions.iconXl * 0.8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3.copyWith(fontSize: 14)),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
