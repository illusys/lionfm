import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/user_provider.dart';
import 'widgets/audio_quality_selector.dart';
import 'widgets/notification_toggles.dart';
import 'widgets/premium_card.dart';
import 'widgets/profile_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppDimensions.p32),
        children: [
          const ProfileHeader(),
          const PremiumCard(),
          // Listening stats
          _StatsGrid(user: user),
          const SizedBox(height: AppDimensions.p24),
          const NotificationToggles(),
          const SizedBox(height: AppDimensions.p24),
          const AudioQualitySelector(),
          const SizedBox(height: AppDimensions.p24),
          // About section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.aboutSection, style: AppTextStyles.label),
                const SizedBox(height: AppDimensions.p12),
                _AboutTile(
                  title: AppStrings.aboutLionFm,
                  onTap: () => launchUrl(Uri.parse(AppStrings.webUrl)),
                ),
                _AboutTile(
                  title: AppStrings.aboutPlatform,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Built with ❤️ by iLLuSys LTD')),
                    );
                  },
                ),
                _AboutTile(
                  title: AppStrings.privacyPolicy,
                  onTap: () => launchUrl(Uri.parse(AppStrings.privacyUrl)),
                ),
                _AboutTile(
                  title: AppStrings.rateApp,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Opening app store…')),
                    );
                  },
                ),
                _AboutTile(
                  title: AppStrings.contactLionFm,
                  onTap: () =>
                      launchUrl(Uri.parse(AppStrings.contactEmail)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final dynamic user;
  const _StatsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Total this month', '${(user.totalListeningMinutes / 60).floor()}h'),
      ('Episodes played', '${user.episodesPlayed}'),
      ('Top category', user.topCategory),
      ('Listener rank', '#1,247'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppDimensions.p12,
        mainAxisSpacing: AppDimensions.p12,
        childAspectRatio: 1.8,
        children: stats.map((s) {
          final (label, value) = s;
          return Container(
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
                Text(label, style: AppTextStyles.caption),
                Text(value,
                    style: AppTextStyles.h2.copyWith(color: AppColors.amberGold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _AboutTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textTertiary, size: 20),
      onTap: onTap,
    );
  }
}
