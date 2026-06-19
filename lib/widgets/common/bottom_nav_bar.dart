import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Schedule', route: '/schedule'),
    _NavItem(icon: Icons.mic_rounded, label: 'Podcasts', route: '/podcasts'),
    _NavItem(icon: Icons.article_rounded, label: 'News', route: '/news'),
    _NavItem(icon: Icons.send_rounded, label: 'Request', route: '/requests'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        border: Border(top: BorderSide(color: AppColors.borderGreen, width: 1)),
      ),
      child: Row(
        children: _items.map((item) {
          final isSelected = item.route == '/'
              ? location == '/'
              : location.startsWith(item.route);
          return Expanded(child: _NavTab(item: item, isSelected: isSelected));
        }).toList(),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  const _NavTab({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                color: AppColors.lionGreen,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 8),
          Icon(
            item.icon,
            color: isSelected ? AppColors.lionGreen : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppTextStyles.navLabel.copyWith(
              color: isSelected ? AppColors.lionGreen : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
