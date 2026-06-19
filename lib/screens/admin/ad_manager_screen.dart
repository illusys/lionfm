import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class AdManagerScreen extends StatelessWidget {
  const AdManagerScreen({super.key});

  final _ads = const [
    ('UNN Bookshop', 'home_mid', 'Jun 30', '12,340 views', '2.4%'),
    ('Campus Pizza', 'news_top', 'Jul 15', '8,120 views', '3.1%'),
    ('TechHub Nsukka', 'schedule_bottom', 'Jun 25', '4,560 views', '1.8%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Ad Manager'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create new ad campaign')),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Stats row
          Row(
            children: [
              _AdStat(label: 'Active', value: '3', color: AppColors.lionGreen),
              const SizedBox(width: 12),
              _AdStat(label: 'Revenue', value: '₦142k', color: AppColors.lionGold),
              const SizedBox(width: 12),
              _AdStat(label: 'Avg CTR', value: '2.4%', color: AppColors.electricTeal),
            ],
          ),
          const SizedBox(height: AppDimensions.p16),
          Text('ACTIVE CAMPAIGNS', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p8),
          ..._ads.map((ad) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ad.$1, style: AppTextStyles.bodyMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lionGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.rFull),
                      ),
                      child: Text('ACTIVE', style: AppTextStyles.caption.copyWith(color: AppColors.lionGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Placement: ${ad.$2} · Expires: ${ad.$3}', style: AppTextStyles.caption),
                Text('${ad.$4} · CTR ${ad.$5}', style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _AdStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AdStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
