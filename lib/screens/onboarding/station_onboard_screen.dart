import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../models/station.dart';

class StationOnboardScreen extends StatefulWidget {
  const StationOnboardScreen({super.key});

  @override
  State<StationOnboardScreen> createState() => _StationOnboardScreenState();
}

class _StationOnboardScreenState extends State<StationOnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  StationPlan _plan = StationPlan.starter;
  bool _submitting = false;
  bool _submitted = false;

  static const _planLabels = {
    StationPlan.free: 'Free',
    StationPlan.starter: 'Starter — ₦5,000/month',
    StationPlan.pro: 'Pro — ₦20,000/month',
    StationPlan.enterprise: 'Enterprise — ₦50,000/month',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _freqCtrl.dispose();
    _contactNameCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _sanitizeSlug(String v) =>
      v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-').replaceAll(RegExp(r'-+'), '-');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('station_onboarding').add({
        'stationName': _nameCtrl.text.trim(),
        'slug': _sanitizeSlug(_slugCtrl.text.trim()),
        'frequency': _freqCtrl.text.trim(),
        'contactName': _contactNameCtrl.text.trim(),
        'contactEmail': _emailCtrl.text.trim().toLowerCase(),
        'country': _countryCtrl.text.trim(),
        'planPreference': switch (_plan) {
          StationPlan.enterprise => 'enterprise',
          StationPlan.pro => 'pro',
          StationPlan.starter => 'starter',
          StationPlan.free => 'free',
        },
        'message': _messageCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.lionGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.lionGold, size: 36),
            ),
            const SizedBox(height: AppDimensions.p24),
            Text('Application Received!',
                style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.p12),
            Text(
              'Thank you for your interest in FMStream. Our team will review your application and reach out to ${_emailCtrl.text} within 48 hours.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p24, vertical: AppDimensions.p32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('Join FMStream',
                    style: AppTextStyles.heroTitle
                        .copyWith(color: AppColors.lionGold)),
                const SizedBox(height: 8),
                Text('Radio infrastructure for Africa. Fill in your station details and we\'ll be in touch.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppDimensions.p32),

                _Label('Station Details'),
                const SizedBox(height: AppDimensions.p12),
                _field(_nameCtrl, 'Station Name', required: true,
                    hint: 'e.g. Lagoon FM'),
                const SizedBox(height: AppDimensions.p12),
                _field(_slugCtrl, 'Desired Subdomain', required: true,
                    hint: 'e.g. lagoon → lagoon.fmstream.online',
                    validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final clean = _sanitizeSlug(v);
                  if (clean.length < 2) return 'At least 2 characters';
                  if (clean.length > 30) return 'Max 30 characters';
                  return null;
                }),
                const SizedBox(height: AppDimensions.p12),
                _field(_freqCtrl, 'Broadcast Frequency',
                    hint: 'e.g. 94.5 MHz (optional)'),
                const SizedBox(height: AppDimensions.p24),

                _Label('Contact'),
                const SizedBox(height: AppDimensions.p12),
                _field(_contactNameCtrl, 'Contact Name', required: true),
                const SizedBox(height: AppDimensions.p12),
                _field(_emailCtrl, 'Contact Email', required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
                const SizedBox(height: AppDimensions.p12),
                _field(_countryCtrl, 'Country', hint: 'e.g. Nigeria'),
                const SizedBox(height: AppDimensions.p24),

                _Label('Plan Preference'),
                const SizedBox(height: AppDimensions.p12),
                DropdownButtonFormField<StationPlan>(
                  value: _plan,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(),
                  items: StationPlan.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_planLabels[p]!,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _plan = v!),
                ),
                const SizedBox(height: AppDimensions.p24),

                _Label('Message (optional)'),
                const SizedBox(height: AppDimensions.p12),
                _field(_messageCtrl, 'Tell us about your station',
                    maxLines: 4, maxLength: 500),
                const SizedBox(height: AppDimensions.p32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.bg0),
                          )
                        : const Text('Submit Application'),
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
                Text(
                  'By submitting, you agree to our terms of service. '
                  'Trial periods are 30 days.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTextStyles.label.copyWith(
            color: AppColors.lionGold, letterSpacing: 1, fontSize: 11),
      );
}
