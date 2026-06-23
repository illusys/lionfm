import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _items = [
    ('Live campus radio', 'Listen to Lion FM 91.1 MHz anywhere with background playback.'),
    ('Guest or signed in', 'Browse freely as a guest, then sign in for requests, tickets, and preferences.'),
    ('Notifications on your terms', 'Enable show alerts, breaking news, and event reminders only when you want them.'),
    ('Premium and live events', 'Go ad-free, unlock high quality, and access eligible event streams.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Lion FM', style: AppTextStyles.h1),
              const SizedBox(height: AppDimensions.p8),
              Text(
                'Official campus radio for University of Nigeria, Nsukka.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.p24),
              ..._items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.p16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radio, color: AppColors.lionGold),
                        const SizedBox(width: AppDimensions.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 4),
                              Text(item.$2, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Start listening'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
