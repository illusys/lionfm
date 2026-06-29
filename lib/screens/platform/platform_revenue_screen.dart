import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/billing_plans.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';

class PlatformRevenueScreen extends ConsumerWidget {
  const PlatformRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(allStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Revenue', style: AppTextStyles.h2),
      ),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (stations) => _RevenueBody(stations: stations),
      ),
    );
  }
}

class _RevenueBody extends StatelessWidget {
  final List<Station> stations;
  const _RevenueBody({required this.stations});

  int get _mrr => stations
      .where((s) => s.isActive && s.planStatus == StationPlanStatus.active)
      .fold(0, (sum, s) => sum + BillingPlans.priceForPlan(s.plan));

  int get _trialing => stations
      .where((s) => s.planStatus == StationPlanStatus.trialing)
      .length;

  int get _pastDue => stations
      .where((s) => s.planStatus == StationPlanStatus.pastDue)
      .length;

  List<Station> get _billedStations => stations
      .where((s) => s.plan != StationPlan.free)
      .toList()
    ..sort((a, b) => BillingPlans.priceForPlan(b.plan)
        .compareTo(BillingPlans.priceForPlan(a.plan)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _RevCard(
                label: 'Monthly Recurring Revenue',
                value: _fmtNGN(_mrr),
                sub: 'Active subscriptions only',
                color: AppColors.successGreen,
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: AppDimensions.p12),
              _RevCard(
                label: 'Trialing Stations',
                value: '$_trialing',
                sub: 'Free 14-day trial',
                color: AppColors.warningGold,
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: AppDimensions.p12),
              _RevCard(
                label: 'Past Due',
                value: '$_pastDue',
                sub: 'Awaiting payment',
                color: AppColors.errorRed,
                icon: Icons.warning_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p32),
          Text('Ad Revenue Share', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.p8),
          _card(
            child: Column(
              children: [
                _ShareRow(plan: 'Free stations', platform: 70, station: 30),
                const Divider(color: AppColors.border1, height: 1),
                _ShareRow(plan: 'Starter stations', platform: 60, station: 40),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p32),
          Text('Per-Station Breakdown', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.p8),
          if (_billedStations.isEmpty)
            _card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.p24),
                child: Center(
                  child: Text('No paid stations yet.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                ),
              ),
            )
          else
            _card(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.p16,
                        vertical: AppDimensions.p10),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text('Station',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted))),
                        SizedBox(
                          width: 80,
                          child: Text('Plan',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text('Status',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text('MRR',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border1, height: 1),
                  ..._billedStations.asMap().entries.map((e) {
                    final s = e.value;
                    final isLast = e.key == _billedStations.length - 1;
                    final price = s.planStatus == StationPlanStatus.active
                        ? BillingPlans.priceForPlan(s.plan)
                        : 0;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.p16,
                              vertical: AppDimensions.p12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: AppTextStyles.bodyMedium),
                                    Text(s.contactEmail,
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: _PlanChip(plan: s.plan),
                              ),
                              SizedBox(
                                width: 80,
                                child: _StatusChip(status: s.planStatus),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  price > 0 ? _fmtNGN(price) : '—',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: price > 0
                                          ? AppColors.successGreen
                                          : AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(color: AppColors.border1, height: 1),
                      ],
                    );
                  }),
                  const Divider(color: AppColors.border1, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.p16,
                        vertical: AppDimensions.p12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Total MRR',
                              style: AppTextStyles.bodyMedium),
                        ),
                        Text(_fmtNGN(_mrr),
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.successGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border1),
      ),
      child: child,
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

class _RevCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
  const _RevCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color,
      required this.icon});

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
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p8),
            Text(value,
                style: AppTextStyles.h2.copyWith(color: color, fontSize: 20)),
            Text(sub,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final String plan;
  final int platform;
  final int station;
  const _ShareRow(
      {required this.plan,
      required this.platform,
      required this.station});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
      child: Row(
        children: [
          Expanded(child: Text(plan, style: AppTextStyles.body)),
          Text('Platform $platform% / Station $station%',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted)),
        ],
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

class _StatusChip extends StatelessWidget {
  final StationPlanStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StationPlanStatus.active => ('Active', AppColors.successGreen),
      StationPlanStatus.trialing => ('Trial', AppColors.warningGold),
      StationPlanStatus.pastDue => ('Past Due', AppColors.liveRed),
      StationPlanStatus.suspended => ('Suspended', AppColors.errorRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 10)),
    );
  }
}
