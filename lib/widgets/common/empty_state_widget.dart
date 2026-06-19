import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.headphones,
    this.title = 'Nothing here',
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
