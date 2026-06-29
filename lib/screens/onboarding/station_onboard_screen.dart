import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class StationOnboardScreen extends StatefulWidget {
  const StationOnboardScreen({super.key});

  @override
  State<StationOnboardScreen> createState() => _StationOnboardScreenState();
}

class _StationOnboardScreenState extends State<StationOnboardScreen> {
  static const _teal = Color(0xFF15E0B4);
  static const _dark = Color(0xFF06112B);

  int _step = 0;

  // Step 1 fields
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 2 fields
  final _step2Key = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _termsChecked = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Slug availability
  String _slugStatus = ''; // '', 'checking', 'available', 'taken'
  Timer? _slugDebounce;

  // Submission
  bool _submitting = false;
  String? _successSlug;
  String? _successName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _freqCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _slugDebounce?.cancel();
    super.dispose();
  }

  String _sanitizeSlug(String v) =>
      v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-').replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  void _onSlugChanged(String raw) {
    _slugDebounce?.cancel();
    final slug = _sanitizeSlug(raw);
    if (slug != raw) {
      _slugCtrl.value = _slugCtrl.value.copyWith(
        text: slug,
        selection: TextSelection.collapsed(offset: slug.length),
      );
    }
    if (slug.length < 2) {
      setState(() => _slugStatus = '');
      return;
    }
    setState(() => _slugStatus = 'checking');
    _slugDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('stations')
            .doc(slug)
            .get();
        if (mounted) setState(() => _slugStatus = doc.exists ? 'taken' : 'available');
      } catch (_) {
        if (mounted) setState(() => _slugStatus = '');
      }
    });
  }

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
    if (!_termsChecked) {
      _showError('Please accept the terms of service.');
      return;
    }

    final name = _nameCtrl.text.trim();
    final freq = _freqCtrl.text.trim();
    final slug = _sanitizeSlug(_slugCtrl.text.trim());
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;

    setState(() => _submitting = true);
    try {
      // 1. Create Firebase Auth user
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;

      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      final trialEndsAt = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      );

      // 2. Write users/{uid} first so role is set before subsequent writes
      await db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': name,
        'role': 'superAdmin',
        'stationId': slug,
        'isActive': true,
        'createdAt': now,
      });

      // 3. Write stations/{slug}
      await db.collection('stations').doc(slug).set({
        'stationId': slug,
        'name': name,
        'slug': slug,
        'frequency': freq,
        'tagline': '',
        'logoUrl': '',
        'faviconUrl': '',
        'brandColors': {
          'primary': '#1E9B43',
          'secondary': '#28D7D2',
          'accent': '#C89A29',
          'background': '#0A0A0A',
        },
        'plan': 'starter',
        'planStatus': 'trialing',
        'trialEndsAt': trialEndsAt,
        'streamType': 'byo',
        'streamUrl': '',
        'isActive': true,
        'isFeatured': false,
        'listenerCount': 0,
        'ownerUid': uid,
        'contactEmail': email,
        'customDomain': null,
        'createdAt': now,
        'updatedAt': now,
      });

      // 4. Seed stream_config/{slug}
      await db.collection('stream_config').doc(slug).set({
        'streamUrl': '',
        'updatedAt': now,
        'stationId': slug,
      });

      if (mounted) {
        setState(() {
          _successSlug = slug;
          _successName = name;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'email-already-in-use' => 'An account with this email already exists.',
          'weak-password' => 'Password must be at least 8 characters.',
          _ => e.message ?? 'Authentication failed.',
        };
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_successSlug != null) return _buildSuccess();
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: _step == 0 ? _buildStep1() : _buildStep2(),
    );
  }

  // ── Step 1: Station Details ──────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p24, vertical: AppDimensions.p32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _step1Key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.p16),
                _StepIndicator(current: 0),
                const SizedBox(height: AppDimensions.p32),
                Text('Your station details',
                    style: AppTextStyles.heroTitle
                        .copyWith(color: _teal)),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your station to get started.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.p32),

                _field(_nameCtrl, 'Station name',
                    hint: 'e.g. Lagoon FM', required: true),
                const SizedBox(height: AppDimensions.p16),

                _field(_freqCtrl, 'Broadcast frequency',
                    hint: 'e.g. 91.1 MHz', required: true),
                const SizedBox(height: AppDimensions.p16),

                // Slug with live availability check
                TextFormField(
                  controller: _slugCtrl,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Station slug',
                    hintText: 'e.g. lagoon',
                    hintStyle: AppTextStyles.body
                        .copyWith(color: AppColors.textMuted),
                    suffixIcon: _slugSuffixIcon(),
                    helperText: _slugCtrl.text.isNotEmpty
                        ? '${_sanitizeSlug(_slugCtrl.text)}.fmstream.online'
                        : null,
                    helperStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (_slugStatus == 'taken') return 'This slug is already taken';
                    if (_slugStatus == 'checking') return 'Checking availability…';
                    final s = _sanitizeSlug(v);
                    if (s.length < 2) return 'At least 2 characters';
                    if (s.length > 30) return 'Max 30 characters';
                    return null;
                  },
                  onChanged: _onSlugChanged,
                ),
                const SizedBox(height: AppDimensions.p16),

                _field(_emailCtrl, 'Contact email',
                    hint: 'station@example.com',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
                const SizedBox(height: AppDimensions.p40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_step1Key.currentState!.validate() &&
                          _slugStatus == 'available') {
                        setState(() => _step = 1);
                      } else if (_slugStatus != 'available' &&
                          _slugCtrl.text.isNotEmpty) {
                        _showError('Please wait for slug availability check.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: _dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue →',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _slugSuffixIcon() {
    return switch (_slugStatus) {
      'checking' => const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      'available' => const Icon(Icons.check_circle_rounded,
          color: AppColors.successGreen, size: 20),
      'taken' => const Icon(Icons.cancel_rounded,
          color: AppColors.errorRed, size: 20),
      _ => null,
    };
  }

  // ── Step 2: Account Creation ─────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p24, vertical: AppDimensions.p32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _step2Key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.p16),
                _StepIndicator(current: 1),
                const SizedBox(height: AppDimensions.p32),
                Text('Create your account',
                    style: AppTextStyles.heroTitle
                        .copyWith(color: _teal)),
                const SizedBox(height: 8),
                Text(
                  'Set a password for ${_emailCtrl.text.trim()}',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.p32),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.p16),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.p24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsChecked,
                      onChanged: (v) =>
                          setState(() => _termsChecked = v ?? false),
                      activeColor: _teal,
                      checkColor: _dark,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _termsChecked = !_termsChecked),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I agree to the FMStream terms of service. Trial periods are 14 days.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _step = 0),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: _dark,
                          disabledBackgroundColor:
                              _teal.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.r12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _dark),
                              )
                            : const Text(
                                'Create station',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _dark),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success ──────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final slug = _successSlug!;
    final name = _successName!;
    final dashboardUrl =
        Uri.parse('https://$slug.fmstream.online/#/admin-login');

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0x2615E0B4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _teal, size: 36),
                ),
                const SizedBox(height: AppDimensions.p24),
                Text(
                  'Welcome to FMStream!',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.p12),
                Text(
                  'Your station "$name" is live at $slug.fmstream.online',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.p32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (await canLaunchUrl(dashboardUrl)) {
                        await launchUrl(dashboardUrl,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: _dark,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.r12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to your dashboard →',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark),
                    ),
                  ),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(0, 'Station details'),
        _line(),
        _dot(1, 'Account'),
      ],
    );
  }

  Widget _dot(int step, String label) {
    final active = step == current;
    final done = step < current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF15E0B4)
                : active
                    ? const Color(0xFF15E0B4)
                    : AppColors.bg2,
            shape: BoxShape.circle,
            border: Border.all(
              color: active || done
                  ? const Color(0xFF15E0B4)
                  : AppColors.border1,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Color(0xFF06112B))
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF06112B)
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active || done
                ? const Color(0xFF15E0B4)
                : AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _line() => Expanded(
        child: Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 18),
          color: AppColors.border1,
        ),
      );
}
