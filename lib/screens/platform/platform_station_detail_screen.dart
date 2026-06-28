import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/billing_plans.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';

class PlatformStationDetailScreen extends ConsumerStatefulWidget {
  final String stationId;
  const PlatformStationDetailScreen({super.key, required this.stationId});

  @override
  ConsumerState<PlatformStationDetailScreen> createState() =>
      _PlatformStationDetailScreenState();
}

class _PlatformStationDetailScreenState
    extends ConsumerState<PlatformStationDetailScreen> {
  StationPlan? _plan;
  StationPlanStatus? _planStatus;
  bool? _isActive;
  bool _saving = false;
  bool _generatingLink = false;

  void _initFrom(Station s) {
    _plan ??= s.plan;
    _planStatus ??= s.planStatus;
    _isActive ??= s.isActive;
  }

  Future<void> _save(Station current) async {
    setState(() => _saving = true);
    final updates = <String, dynamic>{};
    if (_plan != current.plan) {
      updates['plan'] = switch (_plan!) {
        StationPlan.enterprise => 'enterprise',
        StationPlan.pro => 'pro',
        StationPlan.starter => 'starter',
        StationPlan.free => 'free',
      };
    }
    if (_planStatus != current.planStatus) {
      updates['planStatus'] = switch (_planStatus!) {
        StationPlanStatus.active => 'active',
        StationPlanStatus.trialing => 'trialing',
        StationPlanStatus.pastDue => 'past_due',
        StationPlanStatus.suspended => 'suspended',
      };
    }
    if (_isActive != current.isActive) {
      updates['isActive'] = _isActive;
    }
    if (updates.isNotEmpty) {
      try {
        await ref
            .read(stationsRepositoryProvider)
            .updateStation(widget.stationId, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Station updated.'),
            backgroundColor: AppColors.successGreen,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ));
        }
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _generatePaymentLink(Station station) async {
    final plan = _plan ?? station.plan;
    if (plan == StationPlan.free) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Free plan has no billing.'),
        backgroundColor: AppColors.warningGold,
      ));
      return;
    }
    setState(() => _generatingLink = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('initStationBilling')
          .call<Map<Object?, Object?>>({
        'stationId': widget.stationId,
        'plan': BillingPlans.planKey(plan),
        'billingEmail': station.contactEmail,
      });
      final url = (Map<String, dynamic>.from(result.data))['authorizationUrl'] as String?;
      if (url != null && mounted) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'Billing error'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
    if (mounted) setState(() => _generatingLink = false);
  }

  @override
  Widget build(BuildContext context) {
    final stationAsync =
        ref.watch(stationProvider(widget.stationId));

    return stationAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(
            child: Text('Error: $e',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.errorRed))),
      ),
      data: (station) {
        _initFrom(station);
        return Scaffold(
          backgroundColor: AppColors.bg0,
          appBar: AppBar(
            backgroundColor: AppColors.bg1,
            title: Text(station.name, style: AppTextStyles.h2),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.p16),
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(station),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lionGold,
                    foregroundColor: AppColors.bg0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bg0))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader('Identity'),
                _InfoRow('Slug', station.slug),
                _InfoRow('Frequency', station.frequency),
                _InfoRow('Tagline', station.tagline),
                if (station.customDomain != null)
                  _InfoRow('Custom Domain', station.customDomain!),
                _InfoRow('Stream URL', station.streamUrl),
                _InfoRow('Stream Type', station.streamType),
                const SizedBox(height: AppDimensions.p24),
                _SectionHeader('Ownership'),
                _InfoRow('Owner UID', station.ownerUid),
                _InfoRow('Contact Email', station.contactEmail),
                _InfoRow('Created',
                    station.createdAt.toLocal().toString().split('.').first),
                const SizedBox(height: AppDimensions.p24),
                _SectionHeader('Plan & Status'),
                const SizedBox(height: AppDimensions.p12),
                _DropdownRow<StationPlan>(
                  label: 'Plan',
                  value: _plan!,
                  items: StationPlan.values,
                  displayName: (p) => switch (p) {
                    StationPlan.enterprise => 'Enterprise',
                    StationPlan.pro => 'Pro',
                    StationPlan.starter => 'Starter',
                    StationPlan.free => 'Free',
                  },
                  onChanged: (v) => setState(() => _plan = v),
                ),
                const SizedBox(height: AppDimensions.p12),
                _DropdownRow<StationPlanStatus>(
                  label: 'Status',
                  value: _planStatus!,
                  items: StationPlanStatus.values,
                  displayName: (s) => switch (s) {
                    StationPlanStatus.active => 'Active',
                    StationPlanStatus.trialing => 'Trialing',
                    StationPlanStatus.pastDue => 'Past Due',
                    StationPlanStatus.suspended => 'Suspended',
                  },
                  onChanged: (v) => setState(() => _planStatus = v),
                ),
                if (station.trialEndsAt != null)
                  _InfoRow('Trial Ends',
                      station.trialEndsAt!.toLocal().toString().split('.').first),
                const SizedBox(height: AppDimensions.p24),
                _SectionHeader('Visibility'),
                const SizedBox(height: AppDimensions.p8),
                Row(
                  children: [
                    Text('Active',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                    const Spacer(),
                    Switch(
                      value: _isActive!,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppColors.lionGold,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p24),
                _SectionHeader('Billing'),
                const SizedBox(height: AppDimensions.p12),
                // Plan price display
                if ((_plan ?? station.plan) != StationPlan.free)
                  _InfoRow(
                    'Monthly Fee',
                    '₦${BillingPlans.priceForPlan(_plan ?? station.plan).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} / month',
                  ),
                if ((_plan ?? station.plan) == StationPlan.free)
                  _InfoRow('Monthly Fee', 'Free — no charge'),
                const SizedBox(height: AppDimensions.p12),
                // Generate payment link
                if ((_plan ?? station.plan) != StationPlan.free)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatingLink
                          ? null
                          : () => _generatePaymentLink(station),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lionGold,
                        foregroundColor: AppColors.bg0,
                      ),
                      icon: _generatingLink
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.bg0),
                            )
                          : const Icon(Icons.link_rounded, size: 18),
                      label: Text(_generatingLink
                          ? 'Generating…'
                          : 'Generate Payment Link'),
                    ),
                  ),
                const SizedBox(height: AppDimensions.p8),
                // Payment history link
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .push('/platform/station/${widget.stationId}/billing'),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('View Payment History'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p8),
      child: Text(title,
          style: AppTextStyles.label
              .copyWith(color: AppColors.lionGold, letterSpacing: 1)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ),
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: items
                .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(displayName(v),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textPrimary))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
