import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

final _revenueSplitProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('admin_config')
      .doc('revenue')
      .snapshots()
      .map((snap) => snap.data() ?? {});
});

class RevenueDashboardScreen extends ConsumerWidget {
  const RevenueDashboardScreen({super.key});

  static const _history = [
    ('Jun 2026', '₦142,500', '+12%'),
    ('May 2026', '₦127,200', '+8%'),
    ('Apr 2026', '₦117,800', '+5%'),
    ('Mar 2026', '₦112,100', '+15%'),
    ('Feb 2026', '₦97,500', '+3%'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitAsync = ref.watch(_revenueSplitProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
          title: const Text('Revenue'), automaticallyImplyLeading: false),
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
                Text(
                  'This Month',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.bg0.withValues(alpha: 0.7)),
                ),
                Text(
                  '₦142,500',
                  style: AppTextStyles.heroTitle
                      .copyWith(color: AppColors.bg0, fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  '+12% vs last month',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.bg0.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p24),

          // Revenue split from Firestore
          Text('REVENUE SPLIT', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          splitAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Could not load split data.',
              style: AppTextStyles.caption,
            ),
            data: (data) {
              final lionPct = (data['lionFmPct'] as num?)?.toInt() ?? 45;
              final illusysPct = (data['illusysPct'] as num?)?.toInt() ?? 40;
              final unnPct = (data['unnPct'] as num?)?.toInt() ?? 15;

              return Column(
                children: [
                  _SplitRow(
                    label: 'Lion FM 91.1',
                    pct: lionPct,
                    color: AppColors.lionGreen,
                  ),
                  _SplitRow(
                    label: 'iLLuSys LTD',
                    pct: illusysPct,
                    color: AppColors.electricTeal,
                  ),
                  _SplitRow(
                    label: 'UNN',
                    pct: unnPct,
                    color: AppColors.lionGold,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.p24),

          // Monthly history (static — replace with Firestore reads when live data available)
          Text('MONTHLY HISTORY', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          ..._history.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(AppDimensions.r12),
                  border: Border.all(color: AppColors.border1),
                ),
                child: Row(
                  children: [
                    Text(h.$1, style: AppTextStyles.body),
                    const Spacer(),
                    Text(
                      h.$2,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.lionGold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      h.$3,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.lionGreen),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;

  const _SplitRow({
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: AppColors.bg4,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$pct%',
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
