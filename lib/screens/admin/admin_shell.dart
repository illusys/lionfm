import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _items = [
    _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin'),
    _AdminNavItem(icon: Icons.calendar_today_rounded, label: 'Schedule', route: '/admin/schedule'),
    _AdminNavItem(icon: Icons.radio_rounded, label: 'Stream', route: '/admin/stream'),
    _AdminNavItem(icon: Icons.notifications_rounded, label: 'Notify', route: '/admin/notifications'),
    _AdminNavItem(icon: Icons.music_note_rounded, label: 'Requests', route: '/admin/requests'),
    _AdminNavItem(icon: Icons.mic_rounded, label: 'Podcasts', route: '/admin/podcasts'),
    _AdminNavItem(icon: Icons.campaign_rounded, label: 'Ads', route: '/admin/ads'),
    _AdminNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', route: '/admin/analytics'),
    _AdminNavItem(icon: Icons.attach_money_rounded, label: 'Revenue', route: '/admin/revenue'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIdx = _items.indexWhere((item) => item.route == location);
    if (selectedIdx < 0) selectedIdx = 0;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Row(
        children: [
          Container(
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.bg1,
              border: Border(right: BorderSide(color: AppColors.borderGreen, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.p16),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.greenTealGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                  alignment: Alignment.center,
                  child: Text('A', style: AppTextStyles.h3.copyWith(color: AppColors.bg0)),
                ),
                const SizedBox(height: AppDimensions.p16),
                const Divider(color: AppColors.border1, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final isActive = i == selectedIdx;
                      return Tooltip(
                        message: item.label,
                        preferBelow: false,
                        child: GestureDetector(
                          onTap: () => context.go(item.route),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.bg2 : Colors.transparent,
                              border: isActive
                                  ? const Border(left: BorderSide(color: AppColors.lionGreen, width: 3))
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Icon(item.icon,
                              color: isActive ? AppColors.lionGreen : AppColors.textMuted,
                              size: 22),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/settings'),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.textMuted, size: 22),
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;
  final String route;
  const _AdminNavItem({required this.icon, required this.label, required this.route});
}
