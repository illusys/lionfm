import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _QuickActionRow(icon: Icons.radio, iconColor: AppColors.electricTeal, title: 'Podcasts', subtitle: 'Latest episodes', onTap: () => context.go('/podcasts')),
          const SizedBox(height: 10),
          _QuickActionRow(icon: Icons.calendar_today, iconColor: AppColors.lionGreen, title: 'Schedule', subtitle: "Today's shows", onTap: () => context.go('/schedule')),
          const SizedBox(height: 10),
          _QuickActionRow(icon: Icons.music_note, iconColor: AppColors.lionGold, title: 'Request a Song', subtitle: 'Dedicate to someone', onTap: () => context.go('/requests')),
          const SizedBox(height: 10),
          _QuickActionRow(icon: Icons.article, iconColor: AppColors.burntAmber, title: 'Campus News', subtitle: 'Campus updates', onTap: () => context.go('/news')),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionRow({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: iconColor)),
          ],
        ),
      ),
    );
  }
}
