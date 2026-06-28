import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';

class PlatformShell extends ConsumerWidget {
  final Widget child;
  const PlatformShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.radio_rounded, label: 'Stations', route: '/platform'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIdx = _navItems.indexWhere((i) => i.route == location);
    if (selectedIdx < 0) selectedIdx = 0;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Row(
        children: [
          Container(
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.bg1,
              border: Border(right: BorderSide(color: AppColors.borderGold, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.p16),
                _PlatformAvatarChip(adminUser: adminUser),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lionGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('OWNER',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.lionGold, fontSize: 8)),
                ),
                const SizedBox(height: AppDimensions.p16),
                const Divider(color: AppColors.border1, height: 1),
                const SizedBox(height: 8),
                // Platform nav items
                ..._navItems.asMap().entries.map((e) {
                  final isActive = e.key == selectedIdx;
                  return Tooltip(
                    message: e.value.label,
                    preferBelow: false,
                    child: GestureDetector(
                      onTap: () => context.go(e.value.route),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.bg2 : Colors.transparent,
                          border: isActive
                              ? const Border(
                                  left: BorderSide(color: AppColors.lionGold, width: 3))
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Icon(e.value.icon,
                            color: isActive ? AppColors.lionGold : AppColors.textMuted,
                            size: 22),
                      ),
                    ),
                  );
                }),
                const Divider(color: AppColors.border1, height: 1),
                // Station admin cross-link
                Tooltip(
                  message: 'Station Admin',
                  child: GestureDetector(
                    onTap: () => context.go('/admin'),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.textMuted, size: 22),
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(color: AppColors.border1, height: 1),
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

class _PlatformAvatarChip extends StatelessWidget {
  final AdminUser? adminUser;
  const _PlatformAvatarChip({this.adminUser});

  @override
  Widget build(BuildContext context) {
    final initial = adminUser != null && adminUser!.displayName.isNotEmpty
        ? adminUser!.displayName[0].toUpperCase()
        : 'P';

    return Tooltip(
      message: adminUser != null
          ? '${adminUser!.displayName}\nPlatform Owner'
          : 'Platform Owner',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.lionGold, AppColors.warningGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.r8),
        ),
        alignment: Alignment.center,
        child: Text(initial, style: AppTextStyles.h3.copyWith(color: AppColors.bg0)),
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
