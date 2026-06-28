import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/billing_provider.dart';
import '../../providers/station_provider.dart';

class PlatformBillingScreen extends ConsumerWidget {
  final String stationId;
  const PlatformBillingScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(stationPaymentsProvider(stationId));
    final stationAsync = ref.watch(stationProvider(stationId));
    final stationName = stationAsync.valueOrNull?.name ?? stationId;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('$stationName — Billing', style: AppTextStyles.h2),
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: AppDimensions.p12),
                  Text('No payments yet.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          // Compute total paid
          final totalKobo = payments
              .where((p) => p['status'] == 'paid')
              .fold<int>(0, (sum, p) => sum + (p['amountKobo'] as int? ?? 0));

          return Column(
            children: [
              // Summary banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.p16),
                color: AppColors.bg1,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Received',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                        Text(
                          '₦${(totalKobo ~/ 100).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
                          style: AppTextStyles.h2
                              .copyWith(color: AppColors.lionGold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${payments.where((p) => p['status'] == 'paid').length} payment${payments.where((p) => p['status'] == 'paid').length == 1 ? '' : 's'}',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.p16),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.p8),
                  itemBuilder: (_, i) => _PaymentRow(payment: payments[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] as String? ?? 'unknown';
    final plan = payment['plan'] as String? ?? '—';
    final amountKobo = payment['amountKobo'] as int? ?? 0;
    final amountNGN = amountKobo ~/ 100;
    final email = payment['billingEmail'] as String? ?? '—';
    final ref = (payment['id'] as String? ?? '').substring(0, 8);

    DateTime? date;
    final raw = payment['paidAt'] ?? payment['createdAt'];
    if (raw is Timestamp) date = raw.toDate();

    final (statusLabel, statusColor) = switch (status) {
      'paid' => ('Paid', AppColors.successGreen),
      'initialized' => ('Pending', AppColors.warningGold),
      _ => ('Failed', AppColors.errorRed),
    };

    return Container(
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
                    Text(plan.toUpperCase(),
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    _StatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(email,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                if (date != null)
                  Text(
                    date.toLocal().toString().split('.').first,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                Text('ref: $ref…',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '₦${amountNGN.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
            style: AppTextStyles.h3.copyWith(
                color: status == 'paid'
                    ? AppColors.successGreen
                    : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

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
