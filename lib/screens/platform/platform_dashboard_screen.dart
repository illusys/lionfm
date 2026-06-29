import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/billing_plans.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';

class PlatformDashboardScreen extends ConsumerWidget {
  const PlatformDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(allStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Platform Dashboard', style: AppTextStyles.h2),
      ),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (stations) => _DashboardBody(stations: stations),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final List<Station> stations;
  const _DashboardBody({required this.stations});

  int get _mrr => stations
      .where((s) => s.isActive && s.planStatus == StationPlanStatus.active)
      .fold(0, (sum, s) => sum + BillingPlans.priceForPlan(s.plan));

  int get _totalListeners =>
      stations.fold(0, (sum, s) => sum + s.listenerCount);

  @override
  Widget build(BuildContext context) {
    final activeCount = stations.where((s) => s.isActive).length;
    final recent = [...stations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentFive = recent.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatCard(
                label: 'Total Stations',
                value: '${stations.length}',
                icon: Icons.radio_rounded,
                color: AppColors.lionGold,
              ),
              const SizedBox(width: AppDimensions.p12),
              _StatCard(
                label: 'Active',
                value: '$activeCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
              ),
              const SizedBox(width: AppDimensions.p12),
              _StatCard(
                label: 'Est. MRR',
                value: _fmtNGN(_mrr),
                icon: Icons.payments_rounded,
                color: AppColors.warningGold,
              ),
              const SizedBox(width: AppDimensions.p12),
              _StatCard(
                label: 'Listeners',
                value: '$_totalListeners',
                icon: Icons.headphones_rounded,
                color: AppColors.electricTeal,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p32),
          Row(
            children: [
              Text('Recent Stations', style: AppTextStyles.h3),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/platform/stations'),
                child: Text('View all →',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.lionGold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          if (recentFive.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.p32),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                border: Border.all(color: AppColors.border1),
              ),
              child: Center(
                child: Text('No stations yet.',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            _RecentTable(stations: recentFive),
          const SizedBox(height: AppDimensions.p32),
          Text('Plan Breakdown', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.p8),
          _PlanBreakdown(stations: stations),
        ],
      ),
    );
  }

  static String _fmtNGN(int amount) {
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '₦$amount';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.p16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: AppDimensions.p8),
            Text(value,
                style: AppTextStyles.h2
                    .copyWith(color: color, fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _RecentTable extends StatelessWidget {
  final List<Station> stations;
  const _RecentTable({required this.stations});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: stations.asMap().entries.map((e) {
          final isLast = e.key == stations.length - 1;
          return Column(
            children: [
              _DashboardStationRow(station: e.value),
              if (!isLast) const Divider(color: AppColors.border1, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DashboardStationRow extends StatelessWidget {
  final Station station;
  const _DashboardStationRow({required this.station});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/platform/station/${station.stationId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: station.isActive
                    ? AppColors.successGreen
                    : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name, style: AppTextStyles.bodyMedium),
                  Text(station.contactEmail,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            _PlanChip(plan: station.plan),
            const SizedBox(width: AppDimensions.p12),
            Text(
              DateFormat('d MMM').format(station.createdAt),
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(width: AppDimensions.p8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PlanBreakdown extends StatelessWidget {
  final List<Station> stations;
  const _PlanBreakdown({required this.stations});

  @override
  Widget build(BuildContext context) {
    final counts = <StationPlan, int>{};
    for (final s in stations) {
      counts[s.plan] = (counts[s.plan] ?? 0) + 1;
    }
    final rows = [
      (StationPlan.free, 'Free', AppColors.textMuted),
      (StationPlan.starter, 'Starter', AppColors.lionGreen),
      (StationPlan.pro, 'Pro', AppColors.electricTeal),
      (StationPlan.enterprise, 'Enterprise', AppColors.lionGold),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final (plan, label, color) = e.value;
          final count = counts[plan] ?? 0;
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(child: Text(label, style: AppTextStyles.body)),
                    Text(
                      '$count station${count == 1 ? '' : 's'}',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: AppColors.border1, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final StationPlan plan;
  const _PlanChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (plan) {
      StationPlan.enterprise => ('Enterprise', AppColors.lionGold),
      StationPlan.pro => ('Pro', AppColors.electricTeal),
      StationPlan.starter => ('Starter', AppColors.lionGreen),
      StationPlan.free => ('Free', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style:
              AppTextStyles.caption.copyWith(color: color, fontSize: 10)),
    );
  }
}
