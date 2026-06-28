import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';

class PlatformOnboardDetailScreen extends ConsumerStatefulWidget {
  final String onboardingId;
  const PlatformOnboardDetailScreen({super.key, required this.onboardingId});

  @override
  ConsumerState<PlatformOnboardDetailScreen> createState() =>
      _PlatformOnboardDetailScreenState();
}

class _PlatformOnboardDetailScreenState
    extends ConsumerState<PlatformOnboardDetailScreen> {
  late final TextEditingController _slugCtrl;
  late final TextEditingController _trialCtrl;
  StationPlan _plan = StationPlan.starter;
  bool _provisioning = false;
  bool _rejecting = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _slugCtrl = TextEditingController();
    _trialCtrl = TextEditingController(text: '30');
    _loadData();
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _trialCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance
        .collection('station_onboarding')
        .doc(widget.onboardingId)
        .get();
    if (!snap.exists || !mounted) return;
    final d = snap.data()!;
    setState(() {
      _data = {'id': snap.id, ...d};
      _slugCtrl.text = d['slug'] as String? ?? '';
      final planStr = d['planPreference'] as String? ?? 'starter';
      _plan = switch (planStr) {
        'enterprise' => StationPlan.enterprise,
        'pro' => StationPlan.pro,
        'free' => StationPlan.free,
        _ => StationPlan.starter,
      };
    });
  }

  Future<void> _provision() async {
    final slug = _slugCtrl.text.trim();
    if (slug.isEmpty) {
      _snack('Slug is required', AppColors.errorRed);
      return;
    }
    final trialDays = int.tryParse(_trialCtrl.text.trim()) ?? 30;
    setState(() => _provisioning = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('onboardStation')
          .call<Map<Object?, Object?>>({
        'onboardingId': widget.onboardingId,
        'slug': slug,
        'plan': switch (_plan) {
          StationPlan.enterprise => 'enterprise',
          StationPlan.pro => 'pro',
          StationPlan.starter => 'starter',
          StationPlan.free => 'free',
        },
        'trialDays': trialDays,
      });
      if (mounted) {
        _snack('Station "$slug" provisioned! Admin invite sent.', AppColors.successGreen);
        await _loadData();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _snack(e.message ?? 'Provision failed', AppColors.errorRed);
    } catch (e) {
      if (mounted) _snack('Error: $e', AppColors.errorRed);
    }
    if (mounted) setState(() => _provisioning = false);
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        title: Text('Reject Application?', style: AppTextStyles.h3),
        content: Text(
          'This will mark the application as rejected. The applicant will not be notified automatically.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Reject',
                  style: TextStyle(color: AppColors.errorRed))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _rejecting = true);
    try {
      await FirebaseFirestore.instance
          .collection('station_onboarding')
          .doc(widget.onboardingId)
          .update({'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()});
      if (mounted) {
        _snack('Application rejected.', AppColors.warningGold);
        await _loadData();
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', AppColors.errorRed);
    }
    if (mounted) setState(() => _rejecting = false);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final d = _data!;
    final status = d['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final isProvisioned = status == 'provisioned';

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text(d['stationName'] as String? ?? 'Application', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _StatusBanner(status: status),
              const SizedBox(height: AppDimensions.p24),

              // Submitted details
              _Section('Application Details'),
              _Row('Station Name', d['stationName']),
              _Row('Requested Slug', '${d['slug']}.fmstream.online'),
              _Row('Frequency', d['frequency']),
              _Row('Contact Name', d['contactName']),
              _Row('Contact Email', d['contactEmail']),
              _Row('Country', d['country']),
              _Row('Plan Preference', d['planPreference']),
              if ((d['message'] as String? ?? '').isNotEmpty)
                _Row('Message', d['message']),
              const SizedBox(height: AppDimensions.p24),

              if (isProvisioned) ...[
                _Row('Provisioned Slug', d['provisionedSlug']),
              ],

              // Actions — only show if pending
              if (isPending) ...[
                _Section('Provision Station'),
                const SizedBox(height: AppDimensions.p4),
                Text(
                  'Review the slug and plan before provisioning. The contact email will receive an admin invite link.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppDimensions.p16),
                TextFormField(
                  controller: _slugCtrl,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Station Slug',
                    helperText: 'Will be served at [slug].fmstream.online',
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                DropdownButtonFormField<StationPlan>(
                  initialValue: _plan,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: [
                    StationPlan.free, StationPlan.starter,
                    StationPlan.pro, StationPlan.enterprise,
                  ].map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      switch (p) {
                        StationPlan.enterprise => 'Enterprise',
                        StationPlan.pro => 'Pro',
                        StationPlan.starter => 'Starter',
                        StationPlan.free => 'Free',
                      },
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _plan = v!),
                ),
                const SizedBox(height: AppDimensions.p12),
                TextFormField(
                  controller: _trialCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Trial Days',
                    helperText: 'Number of days before billing starts',
                  ),
                ),
                const SizedBox(height: AppDimensions.p24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _provisioning ? null : _provision,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lionGold,
                          foregroundColor: AppColors.bg0,
                        ),
                        icon: _provisioning
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bg0))
                            : const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: Text(_provisioning ? 'Provisioning…' : 'Provision Station'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    OutlinedButton(
                      onPressed: _rejecting ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      child: _rejecting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.errorRed))
                          : const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'provisioned' => ('Provisioned', AppColors.successGreen, Icons.check_circle_rounded),
      'rejected' => ('Rejected', AppColors.errorRed, Icons.cancel_rounded),
      _ => ('Pending Review', AppColors.warningGold, Icons.hourglass_top_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.p8),
        child: Text(title.toUpperCase(),
            style: AppTextStyles.label.copyWith(
                color: AppColors.lionGold, letterSpacing: 1, fontSize: 11)),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final dynamic value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final v = (value as String? ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(v,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
