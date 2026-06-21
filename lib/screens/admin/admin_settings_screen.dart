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
  bool _loading = true;
  bool _saving = false;

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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final streamDoc = await FirebaseFirestore.instance
          .collection('stream_config')
          .doc('current')
          .get();
      final platformDoc = await FirebaseFirestore.instance
          .collection('admin_config')
          .doc('platform')
          .get();

      if (mounted) {
        setState(() {
          _streamUrlCtrl.text =
              streamDoc.data()?['streamUrl'] as String? ?? '';
          _stationNameCtrl.text =
              platformDoc.data()?['stationName'] as String? ??
                  'Lion FM 91.1 MHz';
          _premiumPriceCtrl.text =
              (platformDoc.data()?['premiumPriceNGN'] ?? '').toString();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection('stream_config')
            .doc('current')
            .set({'streamUrl': _streamUrlCtrl.text.trim()},
                SetOptions(merge: true)),
        FirebaseFirestore.instance
            .collection('admin_config')
            .doc('platform')
            .set({
          'stationName': _stationNameCtrl.text.trim(),
          'premiumPriceNGN':
              int.tryParse(_premiumPriceCtrl.text.trim()) ?? 0,
        }, SetOptions(merge: true)),
      ]);
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
            'Delete all requests with status "done"? This cannot be undone.'),
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
      final snap = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'done')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted ${snap.docs.length} completed requests'),
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
      final showsSnap = await FirebaseFirestore.instance
          .collection('shows')
          .get();
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final rows = <List<dynamic>>[
        ['--- SHOWS ---'],
        ['Title', 'Host', 'Schedule'],
        ...showsSnap.docs.map((d) => [
              d.data()['title'] ?? '',
              d.data()['host'] ?? '',
              d.data()['schedule'] ?? '',
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
                label: 'Rules', value: 'Role-based (superAdmin/stationManager/broadcaster/unnAdmin)'),
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
                Text('REVENUE SPLIT',
                    style: AppTextStyles.label),
                const SizedBox(height: 12),
                _RevenueSplitRow(label: 'Lion FM (UNN)', percent: '45%',
                    color: AppColors.lionGreen),
                const SizedBox(height: 8),
                _RevenueSplitRow(label: 'iLLuSys LTD', percent: '40%',
                    color: AppColors.electricTeal),
                const SizedBox(height: 8),
                _RevenueSplitRow(label: 'Operations', percent: '15%',
                    color: AppColors.warningGold),
                const SizedBox(height: 8),
                Text(
                  'Contact iLLuSys LTD to modify revenue split.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p24),

          // B) Firebase Configuration
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

          // C) Danger Zone
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
                  subtitle: 'Delete all requests with status "done"',
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
              borderSide: const BorderSide(
                  color: AppColors.lionGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16, vertical: AppDimensions.p12),
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
      {required this.label,
      required this.percent,
      required this.color});

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
    final color = isDestructive ? AppColors.errorRed : AppColors.textSecondary;

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
                      style: AppTextStyles.bodyMedium.copyWith(color: color)),
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
