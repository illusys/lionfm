import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/'),
    _NavItem(
        icon: Icons.calendar_today_rounded,
        label: 'Schedule',
        route: '/schedule'),
    _NavItem(icon: Icons.mic_rounded, label: 'Podcasts', route: '/podcasts'),
    _NavItem(icon: Icons.article_rounded, label: 'News', route: '/news'),
    _NavItem(icon: Icons.chat_rounded, label: 'Chat', route: '/chat'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        border:
            Border(top: BorderSide(color: AppColors.borderGreen, width: 1)),
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
      child: Stack(
        children: [
          // Accent bar at top for selected state
          if (isSelected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: AppColors.lionGreen,
              ),
            ),
          // Tab content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color:
                      isSelected ? AppColors.lionGreen : AppColors.textMuted,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTextStyles.navLabel.copyWith(
                    color:
                        isSelected ? AppColors.lionGreen : AppColors.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
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
  const _NavItem(
      {required this.icon, required this.label, required this.route});
}
