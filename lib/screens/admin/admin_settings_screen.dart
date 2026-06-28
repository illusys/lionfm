import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/repositories/station_repository.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/current_station_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _streamUrlCtrl = TextEditingController();
  final _stationNameCtrl = TextEditingController();
  final _premiumPriceCtrl = TextEditingController();
  final _paystackPublicKeyCtrl = TextEditingController();

  // Revenue split controllers (superAdmin only)
  final _lionFmPctCtrl = TextEditingController();
  final _illusysPctCtrl = TextEditingController();
  final _unnPctCtrl = TextEditingController();
  String? _revenueSplitError;

  bool _loading = true;
  bool _saving = false;
  bool _seedingStation = false;
  String? _seedStatus;
  bool _stampingDocs = false;
  String? _stampStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _streamUrlCtrl.dispose();
    _stationNameCtrl.dispose();
    _premiumPriceCtrl.dispose();
    _paystackPublicKeyCtrl.dispose();
    _lionFmPctCtrl.dispose();
    _illusysPctCtrl.dispose();
    _unnPctCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stream_config').doc('current').get(),
        FirebaseFirestore.instance.collection('admin_config').doc('platform').get(),
        FirebaseFirestore.instance.collection('admin_config').doc('revenue').get(),
        FirebaseFirestore.instance.collection('admin_config').doc('payments').get(),
      ]);

      final streamDoc = results[0];
      final platformDoc = results[1];
      final revenueDoc = results[2];
      final paymentsDoc = results[3];

      if (mounted) {
        setState(() {
          _streamUrlCtrl.text = streamDoc.data()?['streamUrl'] as String? ?? '';
          _stationNameCtrl.text =
              platformDoc.data()?['stationName'] as String? ?? 'Lion FM 91.1 MHz';
          _premiumPriceCtrl.text =
              (platformDoc.data()?['premiumPriceNGN'] ?? '').toString();
          _paystackPublicKeyCtrl.text =
              paymentsDoc.data()?['publicKey'] as String? ?? '';

          final revenue = revenueDoc.data();
          _lionFmPctCtrl.text =
              (revenue?['lionFmPct'] ?? 45).toString();
          _illusysPctCtrl.text =
              (revenue?['illusysPct'] ?? 40).toString();
          _unnPctCtrl.text =
              (revenue?['unnPct'] ?? 15).toString();

          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lionFmPctCtrl.text = '45';
          _illusysPctCtrl.text = '40';
          _unnPctCtrl.text = '15';
          _loading = false;
        });
      }
    }
  }

  bool _validateRevenueSplit() {
    final a = int.tryParse(_lionFmPctCtrl.text.trim()) ?? 0;
    final b = int.tryParse(_illusysPctCtrl.text.trim()) ?? 0;
    final c = int.tryParse(_unnPctCtrl.text.trim()) ?? 0;
    if (a + b + c != 100) {
      setState(() => _revenueSplitError =
          'The three values must sum to 100 (currently ${a + b + c})');
      return false;
    }
    setState(() => _revenueSplitError = null);
    return true;
  }

  Future<void> _saveSettings() async {
    final adminUser = ref.read(adminUserProvider).valueOrNull;
    final isSuperAdmin = adminUser?.isSuperAdmin == true;

    if (isSuperAdmin && !_validateRevenueSplit()) return;

    final stationId = ref.read(currentStationIdProvider);
    setState(() => _saving = true);
    try {
      final futures = <Future>[
        FirebaseFirestore.instance
            .collection('stream_config')
            .doc('current')
            .set({'streamUrl': _streamUrlCtrl.text.trim()},
                SetOptions(merge: true)),
        FirebaseFirestore.instance
            .collection('admin_config')
            .doc('platform')
            .set({
          'stationId': stationId,
          'stationName': _stationNameCtrl.text.trim(),
          'premiumPriceNGN': int.tryParse(_premiumPriceCtrl.text.trim()) ?? 0,
        }, SetOptions(merge: true)),
      ];

      if (isSuperAdmin) {
        futures.add(
          FirebaseFirestore.instance
              .collection('admin_config')
              .doc('payments')
              .set({
            'stationId': stationId,
            'publicKey': _paystackPublicKeyCtrl.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        );
        futures.add(
          FirebaseFirestore.instance
              .collection('admin_config')
              .doc('revenue')
              .set({
            'stationId': stationId,
            'lionFmPct': int.tryParse(_lionFmPctCtrl.text.trim()) ?? 45,
            'illusysPct': int.tryParse(_illusysPctCtrl.text.trim()) ?? 40,
            'unnPct': int.tryParse(_unnPctCtrl.text.trim()) ?? 15,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': adminUser?.uid ?? '',
          }, SetOptions(merge: true)),
        );
      }

      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearDoneRequests() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Clear Request Queue'),
        content: const Text(
            'Delete all requests with status "played" or "skipped"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final stationId = ref.read(currentStationIdProvider);
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('requests')
            .where('stationId', isEqualTo: stationId)
            .where('status', isEqualTo: 'played')
            .get(),
        FirebaseFirestore.instance
            .collection('requests')
            .where('stationId', isEqualTo: stationId)
            .where('status', isEqualTo: 'skipped')
            .get(),
      ]);

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (final snap in futures) {
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
          count++;
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted $count completed requests'),
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

  Future<void> _exportData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('shows').get(),
        FirebaseFirestore.instance.collection('users').get(),
      ]);
      final showsSnap = results[0];
      final usersSnap = results[1];

      final rows = <List<dynamic>>[
        ['--- SHOWS ---'],
        ['Title', 'Host', 'Days', 'Start', 'End', 'Category'],
        ...showsSnap.docs.map((d) => [
              d.data()['title'] ?? '',
              d.data()['host'] ?? '',
              (d.data()['days'] as List?)?.join(',') ?? '',
              d.data()['startTime'] ?? '',
              d.data()['endTime'] ?? '',
              d.data()['category'] ?? '',
            ]),
        [],
        ['--- USERS ---'],
        ['Name', 'Email', 'Role'],
        ...usersSnap.docs.map((d) => [
              d.data()['displayName'] ?? '',
              d.data()['email'] ?? '',
              d.data()['role'] ?? '',
            ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      await Clipboard.setData(ClipboardData(text: csv));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CSV data copied to clipboard'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    }
  }

  Future<void> _seedLionFmStation() async {
    setState(() {
      _seedingStation = true;
      _seedStatus = null;
    });
    try {
      final message = await StationRepository().seedLionFmStation();
      if (mounted) {
        setState(() => _seedStatus = message ?? 'Lion FM seeded successfully.');
      }
    } catch (e) {
      if (mounted) setState(() => _seedStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _seedingStation = false);
    }
  }

  Future<void> _stampTenantDocs() async {
    setState(() {
      _stampingDocs = true;
      _stampStatus = null;
    });
    try {
      final result = await StationRepository().stampTenantDocs();
      if (mounted) setState(() => _stampStatus = result);
    } catch (e) {
      if (mounted) setState(() => _stampStatus = 'Error: $e');
    } finally {
      if (mounted) setState(() => _stampingDocs = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/admin-login');
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Security Rules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Status', value: 'Active'),
            _InfoRow(label: 'Project', value: 'lionfm-unn'),
            _InfoRow(label: 'Region', value: 'europe-west2 (London)'),
            _InfoRow(
                label: 'Rules',
                value:
                    'Role-based (superAdmin/stationManager/broadcaster/unnAdmin)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final isSuperAdmin = adminUser?.isSuperAdmin == true;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Admin Settings'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveSettings,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.lionGreen))
                : const Text('Save',
                    style: TextStyle(color: AppColors.lionGreen)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // A) Platform Settings
          _SectionHeader(title: 'Platform Settings'),
          const SizedBox(height: AppDimensions.p12),
          _SettingsField(
            label: 'Stream URL',
            controller: _streamUrlCtrl,
            hint: 'https://stream.example.com/live',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppDimensions.p12),
          _SettingsField(
            label: 'Station Name',
            controller: _stationNameCtrl,
            hint: 'Lion FM 91.1 MHz',
          ),
          const SizedBox(height: AppDimensions.p12),
          _SettingsField(
            label: 'Premium Price (NGN)',
            controller: _premiumPriceCtrl,
            hint: '500',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.p16),

          // B) Paystack Configuration (superAdmin only)
          if (isSuperAdmin) ...[
            _SectionHeader(title: 'Paystack Payments'),
            const SizedBox(height: AppDimensions.p12),
            Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsField(
                    label: 'Paystack Public Key',
                    controller: _paystackPublicKeyCtrl,
                    hint: 'pk_test_… or pk_live_…',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The SECRET key is set via Cloud Function config only:\n'
                    '  firebase functions:config:set paystack.secret="sk_live_…"\n\n'
                    'CAUTION: sk_live_* moves real money. Test with sk_test_* first.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),
          ],

          // C) Revenue Split
          _SectionHeader(title: 'Revenue Split'),
          const SizedBox(height: AppDimensions.p12),
          if (isSuperAdmin) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RevenueSplitField(
                    label: 'Lion FM (UNN)',
                    controller: _lionFmPctCtrl,
                    color: AppColors.lionGreen,
                    onChanged: (_) => setState(() => _revenueSplitError = null),
                  ),
                  const SizedBox(height: 10),
                  _RevenueSplitField(
                    label: 'iLLuSys LTD',
                    controller: _illusysPctCtrl,
                    color: AppColors.electricTeal,
                    onChanged: (_) => setState(() => _revenueSplitError = null),
                  ),
                  const SizedBox(height: 10),
                  _RevenueSplitField(
                    label: 'Operations (UNN)',
                    controller: _unnPctCtrl,
                    color: AppColors.warningGold,
                    onChanged: (_) => setState(() => _revenueSplitError = null),
                  ),
                  if (_revenueSplitError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _revenueSplitError!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'All three values must sum to 100.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RevenueSplitRow(
                      label: 'Lion FM (UNN)',
                      percent: '${_lionFmPctCtrl.text}%',
                      color: AppColors.lionGreen),
                  const SizedBox(height: 8),
                  _RevenueSplitRow(
                      label: 'iLLuSys LTD',
                      percent: '${_illusysPctCtrl.text}%',
                      color: AppColors.electricTeal),
                  const SizedBox(height: 8),
                  _RevenueSplitRow(
                      label: 'Operations',
                      percent: '${_unnPctCtrl.text}%',
                      color: AppColors.warningGold),
                  const SizedBox(height: 8),
                  Text(
                    'Only superAdmin can edit the revenue split.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.p24),

          // C) Firebase Configuration
          _SectionHeader(title: 'Firebase Configuration'),
          const SizedBox(height: AppDimensions.p12),
          Container(
            padding: const EdgeInsets.all(AppDimensions.p12),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Firebase Project', value: 'lionfm-unn'),
                const Divider(color: AppColors.border1, height: 16),
                _InfoRow(
                    label: 'Firestore Region',
                    value: 'europe-west2 (London)'),
                const Divider(color: AppColors.border1, height: 16),
                _InfoRow(
                    label: 'Auth Domain',
                    value: 'lionfm-unn.firebaseapp.com'),
                const Divider(color: AppColors.border1, height: 16),
                const _InfoRow(
                    label: 'App Domain', value: 'www.lionfm.online'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p12),
          OutlinedButton.icon(
            onPressed: _showRulesDialog,
            icon: const Icon(Icons.security_rounded, size: 16),
            label: const Text('View Security Rules'),
          ),
          const SizedBox(height: AppDimensions.p24),

          // D) FMStream Migration (superAdmin only)
          if (isSuperAdmin) ...[
            _SectionHeader(title: 'FMStream Migration'),
            const SizedBox(height: AppDimensions.p12),
            Container(
              padding: const EdgeInsets.all(AppDimensions.p12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seed Lion FM as tenant #1 in the stations collection. '
                    'Safe to run multiple times — skips if already seeded.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _seedingStation ? null : _seedLionFmStation,
                      icon: _seedingStation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.lionGold),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: const Text('Seed Lion FM Station'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderGold),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_seedStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _seedStatus!,
                      style: AppTextStyles.caption.copyWith(
                        color: _seedStatus!.startsWith('Error')
                            ? AppColors.errorRed
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Stamp stationId="lion" on all existing documents that '
                    'are missing it. Safe to run more than once.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _stampingDocs ? null : _stampTenantDocs,
                      icon: _stampingDocs
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.lionGold),
                            )
                          : const Icon(Icons.label_outline_rounded, size: 16),
                      label: const Text('Stamp Tenant Docs'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderGold),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_stampStatus != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _stampStatus!,
                      style: AppTextStyles.caption.copyWith(
                        color: _stampStatus!.startsWith('Error')
                            ? AppColors.errorRed
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),
          ],

          // E) Danger Zone
          _SectionHeader(title: 'Danger Zone', color: AppColors.errorRed),
          const SizedBox(height: AppDimensions.p12),
          Container(
            padding: const EdgeInsets.all(AppDimensions.p12),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(
                  color: AppColors.errorRed.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DangerButton(
                  label: 'Clear Request Queue',
                  subtitle: 'Delete all played/skipped requests',
                  onPressed: _clearDoneRequests,
                ),
                const Divider(color: AppColors.border1, height: 24),
                _DangerButton(
                  label: 'Export All Data as CSV',
                  subtitle: 'Shows, users — copied to clipboard',
                  onPressed: _exportData,
                  isDestructive: false,
                ),
                const Divider(color: AppColors.border1, height: 24),
                _DangerButton(
                  label: 'Sign Out of Admin Portal',
                  subtitle: 'Returns to the login screen',
                  onPressed: _signOut,
                  isDestructive: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.label.copyWith(
        color: color ?? AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _SettingsField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bg2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide:
                  const BorderSide(color: AppColors.lionGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
          ),
        ),
      ],
    );
  }
}

class _RevenueSplitField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _RevenueSplitField({
    required this.label,
    required this.controller,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        SizedBox(
          width: 64,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: onChanged,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
            decoration: InputDecoration(
              suffixText: '%',
              suffixStyle:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bg3,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RevenueSplitRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  const _RevenueSplitRow(
      {required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Text(percent,
            style: AppTextStyles.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _DangerButton({
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.errorRed : AppColors.textSecondary;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: color)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
