import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _baseItems = [
    _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin'),
    _AdminNavItem(icon: Icons.calendar_today_rounded, label: 'Schedule', route: '/admin/schedule'),
    _AdminNavItem(icon: Icons.radio_rounded, label: 'Stream', route: '/admin/stream'),
    _AdminNavItem(icon: Icons.notifications_rounded, label: 'Notify', route: '/admin/notifications'),
    _AdminNavItem(icon: Icons.music_note_rounded, label: 'Requests', route: '/admin/requests'),
    _AdminNavItem(icon: Icons.mic_rounded, label: 'Podcasts', route: '/admin/podcasts'),
    _AdminNavItem(icon: Icons.campaign_rounded, label: 'Ads', route: '/admin/ads'),
    _AdminNavItem(icon: Icons.event_rounded, label: 'Events', route: '/admin/events'),
    _AdminNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', route: '/admin/analytics'),
    _AdminNavItem(icon: Icons.attach_money_rounded, label: 'Revenue', route: '/admin/revenue'),
  ];

  static const _superAdminItems = [
    _AdminNavItem(icon: Icons.people_rounded, label: 'Users', route: '/admin/users'),
    _AdminNavItem(icon: Icons.settings_rounded, label: 'Settings', route: '/admin/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;

    final items = [
      ..._baseItems,
      if (adminUser?.isSuperAdmin == true) ..._superAdminItems,
    ];

    int selectedIdx = items.indexWhere((item) => item.route == location);
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
                // Admin identity header
                if (adminUser != null) ...[
                  _AdminAvatarChip(adminUser: adminUser),
                  const SizedBox(height: 4),
                  _RolePill(role: adminUser.role),
                ] else ...[
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenTealGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                    ),
                    alignment: Alignment.center,
                    child: Text('A', style: AppTextStyles.h3.copyWith(color: AppColors.bg0)),
                  ),
                ],
                const SizedBox(height: AppDimensions.p16),
                const Divider(color: AppColors.border1, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
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
                const Divider(color: AppColors.border1, height: 1),
                // Sign out button
                Tooltip(
                  message: 'Sign Out',
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/admin-login');
                    },
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.textMuted, size: 22),
                    ),
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

class _AdminAvatarChip extends StatelessWidget {
  final AdminUser adminUser;
  const _AdminAvatarChip({required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final initial = adminUser.displayName.isNotEmpty
        ? adminUser.displayName[0].toUpperCase()
        : adminUser.email.isNotEmpty
            ? adminUser.email[0].toUpperCase()
            : 'A';

    return Tooltip(
      message: '${adminUser.displayName}\n${AdminUser.roleDisplayName(adminUser.role)}',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.greenTealGradient,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
        ),
        alignment: Alignment.center,
        child: Text(initial, style: AppTextStyles.h3.copyWith(color: AppColors.bg0)),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final AdminRole role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    final label = _shortLabel(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 8)),
    );
  }

  Color _roleColor(AdminRole r) {
    switch (r) {
      case AdminRole.superAdmin: return AppColors.lionGreen;
      case AdminRole.stationManager: return AppColors.electricTeal;
      case AdminRole.broadcaster: return AppColors.warningGold;
      case AdminRole.unnAdmin: return const Color(0xFF4B8EFF);
      case AdminRole.none: return AppColors.textMuted;
    }
  }

  String _shortLabel(AdminRole r) {
    switch (r) {
      case AdminRole.superAdmin: return 'SUPER';
      case AdminRole.stationManager: return 'MGR';
      case AdminRole.broadcaster: return 'BCST';
      case AdminRole.unnAdmin: return 'UNN';
      case AdminRole.none: return '';
    }
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;
  final String route;
  const _AdminNavItem({required this.icon, required this.label, required this.route});
}
