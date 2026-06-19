import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  final _history = const [
    ('Jun 2026', '₦142,500', '+12%'),
    ('May 2026', '₦127,200', '+8%'),
    ('Apr 2026', '₦117,800', '+5%'),
    ('Mar 2026', '₦112,100', '+15%'),
    ('Feb 2026', '₦97,500', '+3%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Revenue'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(AppDimensions.p20),
            decoration: BoxDecoration(
              gradient: AppColors.greenTealGradient,
              borderRadius: BorderRadius.circular(AppDimensions.r16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Month', style: AppTextStyles.caption.copyWith(color: AppColors.bg0.withOpacity(0.7))),
                Text('₦142,500', style: AppTextStyles.heroTitle.copyWith(color: AppColors.bg0, fontSize: 32)),
                const SizedBox(height: 4),
                Text('+12% vs last month', style: AppTextStyles.bodySmall.copyWith(color: AppColors.bg0.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p24),

          // Revenue split
          Text('REVENUE SPLIT', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          ...[
            ('Premium Subscriptions', '₦68,400', '48%', AppColors.lionGreen),
            ('Direct Ads', '₦42,750', '30%', AppColors.electricTeal),
            ('AdMob', '₦19,950', '14%', AppColors.lionGold),
            ('Events & Partnerships', '₦11,400', '8%', AppColors.burntAmber),
          ].map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: Row(
              children: [
                Container(
                  width: 4, height: 40,
                  decoration: BoxDecoration(
                    color: r.$4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: AppTextStyles.bodyMedium),
                      Text(r.$3, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Text(r.$2, style: AppTextStyles.bodyMedium.copyWith(color: r.$4)),
              ],
            ),
          )),
          const SizedBox(height: AppDimensions.p24),

          // History
          Text('MONTHLY HISTORY', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          ..._history.map((h) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: Row(
              children: [
                Text(h.$1, style: AppTextStyles.body),
                const Spacer(),
                Text(h.$2, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lionGold)),
                const SizedBox(width: 12),
                Text(h.$3, style: AppTextStyles.caption.copyWith(color: AppColors.lionGreen)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
