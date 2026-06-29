import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/billing_plans.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';

// Loads platform_config/payments from Firestore
final _platformPaymentsProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  return FirebaseFirestore.instance
      .collection('platform_config')
      .doc('payments')
      .snapshots()
      .map((snap) => snap.data());
});

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  final _webhookCtrl = TextEditingController();
  final _publicKeyCtrl = TextEditingController();
  bool _obscureWebhook = true;
  bool _savingPayments = false;
  bool _loaded = false;

  @override
  void dispose() {
    _webhookCtrl.dispose();
    _publicKeyCtrl.dispose();
    super.dispose();
  }

  void _onPaymentsLoaded(Map<String, dynamic>? data) {
    if (_loaded || data == null) return;
    _loaded = true;
    _publicKeyCtrl.text = data['paystackPublicKey'] as String? ?? '';
    _webhookCtrl.text = data['paystackWebhookSecret'] as String? ?? '';
  }

  Future<void> _savePayments() async {
    setState(() => _savingPayments = true);
    try {
      await FirebaseFirestore.instance
          .collection('platform_config')
          .doc('payments')
          .set({
        'paystackPublicKey': _publicKeyCtrl.text.trim(),
        'paystackWebhookSecret': _webhookCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment config saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPayments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(_platformPaymentsProvider);

    paymentsAsync.whenData(_onPaymentsLoaded);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Platform Settings', style: AppTextStyles.h2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Platform Info ──────────────────────────────────────────────
            Text('Platform Info', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.p8),
            _card(
              child: Column(
                children: [
                  _InfoRow(label: 'Platform', value: 'FMStream by iLLuSys LTD'),
                  const Divider(color: AppColors.border1, height: 1),
                  _InfoRow(label: 'App Domain', value: 'app.fmstream.online'),
                  const Divider(color: AppColors.border1, height: 1),
                  _InfoRow(label: 'Firebase Project', value: 'lionfm-unn'),
                  const Divider(color: AppColors.border1, height: 1),
                  _InfoRow(
                      label: 'Region', value: 'europe-west2 (London)'),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p32),

            // ── Paystack Config ────────────────────────────────────────────
            Text('Paystack Config', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Stored in platform_config/payments. Secret key lives only in Cloud Functions config.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.p12),
            _card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsField(
                      label: 'Paystack Public Key',
                      controller: _publicKeyCtrl,
                      hint: 'pk_live_...',
                    ),
                    const SizedBox(height: AppDimensions.p12),
                    _SettingsField(
                      label: 'Webhook Secret',
                      controller: _webhookCtrl,
                      hint: 'Webhook signing secret',
                      obscure: _obscureWebhook,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureWebhook
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscureWebhook = !_obscureWebhook),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.p16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savingPayments ? null : _savePayments,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lionGold,
                          foregroundColor: AppColors.bg0,
                        ),
                        child: _savingPayments
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.bg0),
                              )
                            : const Text('Save Payment Config'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.p32),

            // ── Plan Pricing ───────────────────────────────────────────────
            Text('Plan Pricing', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Compile-time constants. To change pricing, update billing_plans.dart and redeploy.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimensions.p12),
            _card(
              child: Column(
                children: [
                  _PlanPriceRow(plan: StationPlan.free, label: 'Free'),
                  const Divider(color: AppColors.border1, height: 1),
                  _PlanPriceRow(plan: StationPlan.starter, label: 'Starter'),
                  const Divider(color: AppColors.border1, height: 1),
                  _PlanPriceRow(plan: StationPlan.pro, label: 'Pro'),
                  const Divider(color: AppColors.border1, height: 1),
                  _PlanPriceRow(
                      plan: StationPlan.enterprise, label: 'Enterprise'),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p32),

            // ── Danger Zone ─────────────────────────────────────────────────
            Text('Danger Zone', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.p8),
            _card(
              borderColor: AppColors.errorRed.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform-level destructive actions. These cannot be undone.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppDimensions.p16),
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(
                          context, 'lionfm-unn', 'Firebase project ID copied'),
                      icon: const Icon(Icons.content_copy_rounded, size: 16),
                      label: const Text('Copy Firebase Project ID'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: borderColor ?? AppColors.border1),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final Widget? suffixIcon;
  const _SettingsField(
      {required this.label,
      required this.controller,
      this.hint,
      this.obscure = false,
      this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.bg3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r8),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r8),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p12,
                vertical: AppDimensions.p10),
          ),
        ),
      ],
    );
  }
}

class _PlanPriceRow extends StatelessWidget {
  final StationPlan plan;
  final String label;
  const _PlanPriceRow({required this.plan, required this.label});

  @override
  Widget build(BuildContext context) {
    final price = BillingPlans.priceForPlan(plan);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            price == 0 ? 'Free' : '₦${_fmtK(price)}/month',
            style: AppTextStyles.body.copyWith(
                color: price == 0 ? AppColors.textMuted : AppColors.lionGold),
          ),
        ],
      ),
    );
  }

  static String _fmtK(int amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return '$amount';
  }
}
