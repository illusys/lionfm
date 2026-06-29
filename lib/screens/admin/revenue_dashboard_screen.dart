import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/current_station_provider.dart';

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
    final stationId = ref.watch(currentStationIdProvider);
    final isLionFm = stationId == 'lion';
    final splitAsync = ref.watch(_revenueSplitProvider);
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final isSuperAdmin = adminUser?.isSuperAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
          title: const Text('Revenue'), automaticallyImplyLeading: false),
      body: isLionFm
          ? _buildLionFmRevenue(splitAsync, isSuperAdmin)
          : _buildTenantRevenuePlaceholder(),
    );
  }

  Widget _buildLionFmRevenue(
      AsyncValue<Map<String, dynamic>> splitAsync, bool isSuperAdmin) {
    return ListView(
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

        // Revenue split — read view + superAdmin edit button
        Row(
          children: [
            Text('REVENUE SPLIT', style: AppTextStyles.label),
            const Spacer(),
            if (isSuperAdmin)
              splitAsync.whenData((data) {
                final lion = (data['lionFmPct'] as num?)?.toInt() ?? 45;
                final illusys = (data['illusysPct'] as num?)?.toInt() ?? 40;
                final unn = (data['unnPct'] as num?)?.toInt() ?? 15;
                return _EditSplitButton(
                  lionPct: lion,
                  illusysPct: illusys,
                  unnPct: unn,
                );
              }).valueOrNull ??
                  const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: AppDimensions.p12),
        splitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              Text('Could not load split data.', style: AppTextStyles.caption),
          data: (data) {
            final lionPct = (data['lionFmPct'] as num?)?.toInt() ?? 45;
            final illusysPct = (data['illusysPct'] as num?)?.toInt() ?? 40;
            final unnPct = (data['unnPct'] as num?)?.toInt() ?? 15;
            return Column(
              children: [
                _SplitRow(label: 'Lion FM 91.1', pct: lionPct, color: AppColors.lionGreen),
                _SplitRow(label: 'iLLuSys LTD', pct: illusysPct, color: AppColors.electricTeal),
                _SplitRow(label: 'UNN', pct: unnPct, color: AppColors.lionGold),
              ],
            );
          },
        ),
        const SizedBox(height: AppDimensions.p24),

        // Monthly history
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
                  Text(h.$2,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.lionGold)),
                  const SizedBox(width: 12),
                  Text(h.$3,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.lionGreen)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTenantRevenuePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppDimensions.p16),
            Text('Revenue reporting coming soon',
                style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p8),
            Text(
              'Detailed revenue analytics will be available here once your station goes live.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SuperAdmin: edit split button ────────────────────────────────────────────

class _EditSplitButton extends StatelessWidget {
  final int lionPct;
  final int illusysPct;
  final int unnPct;
  const _EditSplitButton({
    required this.lionPct,
    required this.illusysPct,
    required this.unnPct,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.bg2,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _EditSplitSheet(
          lionPct: lionPct,
          illusysPct: illusysPct,
          unnPct: unnPct,
        ),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.lionGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
              color: AppColors.lionGreen.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Edit Split',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.lionGreen),
        ),
      ),
    );
  }
}

// ─── Edit split bottom sheet ─────────────────────────────────────────────────

class _EditSplitSheet extends StatefulWidget {
  final int lionPct;
  final int illusysPct;
  final int unnPct;
  const _EditSplitSheet({
    required this.lionPct,
    required this.illusysPct,
    required this.unnPct,
  });

  @override
  State<_EditSplitSheet> createState() => _EditSplitSheetState();
}

class _EditSplitSheetState extends State<_EditSplitSheet> {
  late final TextEditingController _lionCtrl;
  late final TextEditingController _illusysCtrl;
  late final TextEditingController _unnCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lionCtrl =
        TextEditingController(text: widget.lionPct.toString());
    _illusysCtrl =
        TextEditingController(text: widget.illusysPct.toString());
    _unnCtrl =
        TextEditingController(text: widget.unnPct.toString());
  }

  @override
  void dispose() {
    _lionCtrl.dispose();
    _illusysCtrl.dispose();
    _unnCtrl.dispose();
    super.dispose();
  }

  int get _lion => int.tryParse(_lionCtrl.text.trim()) ?? 0;
  int get _illusys => int.tryParse(_illusysCtrl.text.trim()) ?? 0;
  int get _unn => int.tryParse(_unnCtrl.text.trim()) ?? 0;
  int get _total => _lion + _illusys + _unn;
  bool get _valid => _total == 100;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('admin_config')
          .doc('revenue')
          .set({
        'lionFmPct': _lion,
        'illusysPct': _illusys,
        'unnPct': _unn,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Revenue Split', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Values must add up to exactly 100.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _SplitField(
            label: 'Lion FM 91.1 (%)',
            ctrl: _lionCtrl,
            color: AppColors.lionGreen,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _SplitField(
            label: 'iLLuSys LTD (%)',
            ctrl: _illusysCtrl,
            color: AppColors.electricTeal,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _SplitField(
            label: 'UNN (%)',
            ctrl: _unnCtrl,
            color: AppColors.lionGold,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Running total indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _valid
                  ? AppColors.lionGreen.withValues(alpha: 0.1)
                  : AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r8),
              border: Border.all(
                  color: _valid
                      ? AppColors.lionGreen.withValues(alpha: 0.4)
                      : AppColors.errorRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  _valid
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: _valid ? AppColors.lionGreen : AppColors.errorRed,
                ),
                const SizedBox(width: 8),
                Text(
                  _valid
                      ? 'Total: 100% ✓'
                      : 'Total: $_total% — must equal 100',
                  style: AppTextStyles.bodySmall.copyWith(
                      color:
                          _valid ? AppColors.lionGreen : AppColors.errorRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_valid && !_saving) ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
              disabledBackgroundColor: AppColors.bg3,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0))
                : const Text('Save Split'),
          ),
        ],
      ),
    );
  }
}

class _SplitField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color color;
  final ValueChanged<String> onChanged;
  const _SplitField({
    required this.label,
    required this.ctrl,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bg3,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: BorderSide(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Split row (read view) ────────────────────────────────────────────────────

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
