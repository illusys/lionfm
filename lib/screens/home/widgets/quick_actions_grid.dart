import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/text_styles.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXPLORE', style: AppTextStyles.categoryLabel),
          const SizedBox(height: AppDimensions.p12),
          _QuickActionRow(
            iconBg: AppColors.electricTeal,
            icon: Icons.mic_rounded,
            iconColor: AppColors.bg0,
            title: 'Podcasts',
            subtitle: 'Recorded shows & episodes',
            accentColor: AppColors.electricTeal,
            onTap: () => context.go('/podcasts'),
          ),
          const SizedBox(height: AppDimensions.p8),
          _QuickActionRow(
            iconBg: AppColors.lionGreen,
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.bg0,
            title: 'Schedule',
            subtitle: 'This week\'s programme',
            accentColor: AppColors.lionGreen,
            onTap: () => context.go('/schedule'),
          ),
          const SizedBox(height: AppDimensions.p8),
          _QuickActionRow(
            iconBg: AppColors.lionGold,
            icon: Icons.music_note_rounded,
            iconColor: AppColors.bg0,
            title: 'Request',
            subtitle: 'Songs & show pitches',
            accentColor: AppColors.lionGold,
            onTap: () => context.go('/requests'),
          ),
          const SizedBox(height: AppDimensions.p8),
          _QuickActionRow(
            iconBg: AppColors.burntAmber,
            icon: Icons.article_rounded,
            iconColor: AppColors.ivoryWhite,
            title: 'Campus News',
            subtitle: 'UNN & beyond',
            accentColor: AppColors.burntAmber,
            onTap: () => context.go('/news'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatefulWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_QuickActionRow> createState() => _QuickActionRowState();
}

class _QuickActionRowState extends State<_QuickActionRow> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(AppDimensions.r16),
            border: Border(
              left: BorderSide(color: widget.accentColor, width: 3),
              top: const BorderSide(color: AppColors.border1),
              right: const BorderSide(color: AppColors.border1),
              bottom: const BorderSide(color: AppColors.border1),
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.p12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(AppDimensions.r12),
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: AppDimensions.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
