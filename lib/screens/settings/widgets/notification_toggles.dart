import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/user_provider.dart';
import '../../../data/services/notification_permission_service.dart';

class NotificationToggles extends ConsumerWidget {
  const NotificationToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.notificationsSection, style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          _ToggleRow(
            icon: Icons.notifications,
            title: AppStrings.showAlerts,
            subtitle: AppStrings.showAlertsSubtitle,
            value: user.notifyShowAlerts,
            onToggle: () async {
              if (!user.notifyShowAlerts) {
                await NotificationPermissionService.requestContextualPermission();
              }
              await ref.read(userProvider.notifier).toggleNotification('showAlerts');
            },
          ),
          _ToggleRow(
            icon: Icons.article,
            title: AppStrings.breakingNews,
            subtitle: AppStrings.breakingNewsSubtitle,
            value: user.notifyBreakingNews,
            onToggle: () async {
              if (!user.notifyBreakingNews) {
                await NotificationPermissionService.requestContextualPermission();
              }
              await ref.read(userProvider.notifier).toggleNotification('breakingNews');
            },
          ),
          _ToggleRow(
            icon: Icons.music_note,
            title: AppStrings.requestConfirmation,
            subtitle: AppStrings.requestConfirmationSubtitle,
            value: user.notifyRequestConfirmation,
            onToggle: () => ref
                .read(userProvider.notifier)
                .toggleNotification('requestConfirmation'),
          ),
          _ToggleRow(
            icon: Icons.campaign,
            title: AppStrings.specialEvents,
            subtitle: AppStrings.specialEventsSubtitle,
            value: user.notifySpecialEvents,
            onToggle: () => ref
                .read(userProvider.notifier)
                .toggleNotification('specialEvents'),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function() onToggle;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p16),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconMd, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          _BrandToggle(value: value, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _BrandToggle extends StatelessWidget {
  final bool value;
  final Future<void> Function() onToggle;

  const _BrandToggle({required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: AppDimensions.toggleWidth,
        height: AppDimensions.toggleHeight,
        decoration: BoxDecoration(
          color: value ? AppColors.successGreen : AppColors.surface3,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
            color: value ? AppColors.successGreen : AppColors.border2,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: value
                  ? AppDimensions.toggleWidth -
                      AppDimensions.toggleThumb -
                      AppDimensions.togglePad
                  : AppDimensions.togglePad,
              top: AppDimensions.togglePad,
              child: Container(
                width: AppDimensions.toggleThumb,
                height: AppDimensions.toggleThumb,
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
