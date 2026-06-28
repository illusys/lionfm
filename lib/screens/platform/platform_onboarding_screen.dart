import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/onboarding_provider.dart';

class PlatformOnboardingScreen extends ConsumerStatefulWidget {
  const PlatformOnboardingScreen({super.key});

  @override
  ConsumerState<PlatformOnboardingScreen> createState() =>
      _PlatformOnboardingScreenState();
}

class _PlatformOnboardingScreenState
    extends ConsumerState<PlatformOnboardingScreen> {
  String _filter = 'all';

  static const _tabs = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('provisioned', 'Provisioned'),
    ('rejected', 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(onboardingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Station Onboarding', style: AppTextStyles.h2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16, vertical: 6),
            child: Row(
              children: _tabs.map((t) {
                final isSelected = _filter == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lionGold.withValues(alpha: 0.2)
                            : AppColors.bg2,
                        borderRadius: BorderRadius.circular(AppDimensions.rFull),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.lionGold
                              : AppColors.border1,
                        ),
                      ),
                      child: Text(t.$2,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.lionGold
                                : AppColors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.errorRed))),
        data: (requests) {
          final filtered = _filter == 'all'
              ? requests
              : requests.where((r) => r['status'] == _filter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                _filter == 'all'
                    ? 'No applications yet.'
                    : 'No $_filter applications.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.p16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.p8),
            itemBuilder: (_, i) => _RequestRow(request: filtered[i]),
          );
        },
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final stationName = request['stationName'] as String? ?? '—';
    final slug = request['slug'] as String? ?? '';
    final email = request['contactEmail'] as String? ?? '—';
    final plan = request['planPreference'] as String? ?? '—';

    DateTime? date;
    final raw = request['createdAt'];
    if (raw is Timestamp) date = raw.toDate();

    final (statusLabel, statusColor) = switch (status) {
      'provisioned' => ('Provisioned', AppColors.successGreen),
      'rejected' => ('Rejected', AppColors.errorRed),
      _ => ('Pending', AppColors.warningGold),
    };

    return GestureDetector(
      onTap: () => context.push('/platform/onboarding/${request['id']}'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.p16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
          border: Border.all(color: AppColors.border1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(stationName,
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _StatusChip(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (slug.isNotEmpty)
                    Text('$slug.fmstream.online',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.lionGold)),
                  Text(email,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  Text(plan.toUpperCase(),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
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
