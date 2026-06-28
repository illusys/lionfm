import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';

class PlatformStationsScreen extends ConsumerWidget {
  const PlatformStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(allStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('FMStream Stations', style: AppTextStyles.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.p16),
            child: stationsAsync.whenOrNull(
              data: (s) => Text('${s.length} station${s.length == 1 ? '' : 's'}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (stations) {
          if (stations.isEmpty) {
            return Center(
              child: Text('No stations yet.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.p16),
            itemCount: stations.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.p8),
            itemBuilder: (_, i) => _StationRow(station: stations[i]),
          );
        },
      ),
    );
  }
}

class _StationRow extends ConsumerWidget {
  final Station station;
  const _StationRow({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/platform/station/${station.stationId}'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.p16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
          border: Border.all(color: AppColors.border1),
        ),
        child: Row(
          children: [
            // Active indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: station.isActive ? AppColors.successGreen : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.p12),
            // Station info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${station.slug} · ${station.frequency}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  if (station.contactEmail.isNotEmpty)
                    Text(station.contactEmail,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.p12),
            // Badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PlanBadge(plan: station.plan),
                const SizedBox(height: 4),
                _StatusBadge(status: station.planStatus),
              ],
            ),
            const SizedBox(width: AppDimensions.p8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final StationPlan plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (plan) {
      StationPlan.enterprise => ('Enterprise', AppColors.lionGold),
      StationPlan.pro => ('Pro', AppColors.electricTeal),
      StationPlan.starter => ('Starter', AppColors.lionGreen),
      StationPlan.free => ('Free', AppColors.textMuted),
    };
    return _Badge(label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  final StationPlanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StationPlanStatus.active => ('Active', AppColors.successGreen),
      StationPlanStatus.trialing => ('Trial', AppColors.warningGold),
      StationPlanStatus.pastDue => ('Past Due', AppColors.liveRed),
      StationPlanStatus.suspended => ('Suspended', AppColors.errorRed),
    };
    return _Badge(label: label, color: color);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
