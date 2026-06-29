import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class PlatformAd {
  final String id;
  final String type; // 'banner' | 'audio'
  final String title;
  final String imageUrl;
  final String audioUrl;
  final String linkUrl;
  final bool isActive;
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  const PlatformAd({
    required this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.audioUrl,
    required this.linkUrl,
    required this.isActive,
    required this.impressions,
    required this.clicks,
    required this.createdAt,
  });

  factory PlatformAd.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PlatformAd(
      id: doc.id,
      type: d['type'] as String? ?? 'banner',
      title: d['title'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      audioUrl: d['audioUrl'] as String? ?? '',
      linkUrl: d['linkUrl'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
      impressions: d['impressions'] as int? ?? 0,
      clicks: d['clicks'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get ctr =>
      impressions > 0 ? (clicks / impressions * 100) : 0.0;
}

// ── Provider ─────────────────────────────────────────────────────────────────

final _platformAdsProvider =
    StreamProvider<List<PlatformAd>>((ref) {
  return FirebaseFirestore.instance
      .collection('platform_ads')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(PlatformAd.fromDoc).toList());
});

// ── Screen ───────────────────────────────────────────────────────────────────

class PlatformAdsScreen extends ConsumerStatefulWidget {
  const PlatformAdsScreen({super.key});

  @override
  ConsumerState<PlatformAdsScreen> createState() => _PlatformAdsScreenState();
}

class _PlatformAdsScreenState extends ConsumerState<PlatformAdsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(_platformAdsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        title: Text('Platform Ads', style: AppTextStyles.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.p16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lionGold,
                foregroundColor: AppColors.bg0,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.lionGold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.lionGold,
          tabs: const [
            Tab(text: 'Banner'),
            Tab(text: 'Audio'),
          ],
        ),
      ),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (ads) => TabBarView(
          controller: _tabs,
          children: [
            _AdList(
              ads: ads.where((a) => a.type == 'banner').toList(),
              type: 'banner',
              onToggle: _toggleAd,
              onDelete: _deleteAd,
            ),
            _AdList(
              ads: ads.where((a) => a.type == 'audio').toList(),
              type: 'audio',
              onToggle: _toggleAd,
              onDelete: _deleteAd,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAd(PlatformAd ad) async {
    await FirebaseFirestore.instance
        .collection('platform_ads')
        .doc(ad.id)
        .update({'isActive': !ad.isActive});
  }

  Future<void> _deleteAd(PlatformAd ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg3,
        title: Text('Delete "${ad.title}"?',
            style: AppTextStyles.h3),
        content: Text('This cannot be undone.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('platform_ads')
          .doc(ad.id)
          .delete();
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateAdDialog(
        onSubmit: (data) async {
          await FirebaseFirestore.instance.collection('platform_ads').add({
            ...data,
            'impressions': 0,
            'clicks': 0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }
}

// ── Ad List ──────────────────────────────────────────────────────────────────

class _AdList extends StatelessWidget {
  final List<PlatformAd> ads;
  final String type;
  final Future<void> Function(PlatformAd) onToggle;
  final Future<void> Function(PlatformAd) onDelete;

  const _AdList({
    required this.ads,
    required this.type,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type == 'banner' ? Icons.image_rounded : Icons.graphic_eq_rounded,
                color: AppColors.textMuted, size: 40),
            const SizedBox(height: AppDimensions.p12),
            Text('No ${type == 'banner' ? 'banner' : 'audio'} ads yet.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.p16),
      itemCount: ads.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.p8),
      itemBuilder: (_, i) => _AdCard(
        ad: ads[i],
        onToggle: onToggle,
        onDelete: onDelete,
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final PlatformAd ad;
  final Future<void> Function(PlatformAd) onToggle;
  final Future<void> Function(PlatformAd) onDelete;

  const _AdCard(
      {required this.ad, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ad.title,
                    style: AppTextStyles.bodyMedium),
              ),
              _StatusPill(isActive: ad.isActive),
              const SizedBox(width: AppDimensions.p8),
              PopupMenuButton<String>(
                color: AppColors.bg3,
                icon: Icon(Icons.more_vert,
                    color: AppColors.textMuted, size: 18),
                onSelected: (v) {
                  if (v == 'toggle') onToggle(ad);
                  if (v == 'delete') onDelete(ad);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      ad.isActive ? 'Pause' : 'Activate',
                      style: AppTextStyles.body,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.errorRed)),
                  ),
                ],
              ),
            ],
          ),
          if (ad.linkUrl.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ad.linkUrl,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              _StatChip(
                label: 'Impressions',
                value: '${ad.impressions}',
              ),
              const SizedBox(width: AppDimensions.p8),
              _StatChip(label: 'Clicks', value: '${ad.clicks}'),
              const SizedBox(width: AppDimensions.p8),
              _StatChip(
                  label: 'CTR',
                  value: '${ad.ctr.toStringAsFixed(1)}%'),
              const Spacer(),
              Text(
                DateFormat('d MMM y').format(ad.createdAt),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.successGreen : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isActive ? 'Active' : 'Paused',
        style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ── Create Ad Dialog ─────────────────────────────────────────────────────────

class _CreateAdDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _CreateAdDialog({required this.onSubmit});

  @override
  State<_CreateAdDialog> createState() => _CreateAdDialogState();
}

class _CreateAdDialogState extends State<_CreateAdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  String _type = 'banner';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _imageUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
    _linkUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg3,
      title: Text('Create Platform Ad', style: AppTextStyles.h3),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeChip(
                    label: 'Banner',
                    selected: _type == 'banner',
                    onTap: () => setState(() => _type = 'banner'),
                  ),
                  const SizedBox(width: AppDimensions.p8),
                  _TypeChip(
                    label: 'Audio',
                    selected: _type == 'audio',
                    onTap: () => setState(() => _type = 'audio'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.p16),
              _Field(
                label: 'Title',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              if (_type == 'banner') ...[
                const SizedBox(height: AppDimensions.p12),
                _Field(
                  label: 'Image URL',
                  controller: _imageUrlCtrl,
                  hint: 'https://...',
                ),
              ],
              if (_type == 'audio') ...[
                const SizedBox(height: AppDimensions.p12),
                _Field(
                  label: 'Audio URL',
                  controller: _audioUrlCtrl,
                  hint: 'https://... (.mp3)',
                ),
              ],
              const SizedBox(height: AppDimensions.p12),
              _Field(
                label: 'Click URL',
                controller: _linkUrlCtrl,
                hint: 'https://...',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lionGold,
            foregroundColor: AppColors.bg0,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'type': _type,
        'title': _titleCtrl.text.trim(),
        'imageUrl': _imageUrlCtrl.text.trim(),
        'audioUrl': _audioUrlCtrl.text.trim(),
        'linkUrl': _linkUrlCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.lionGold : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
              color:
                  selected ? AppColors.lionGold : AppColors.border2),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.bg0 : AppColors.textMuted,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  const _Field(
      {required this.label,
      required this.controller,
      this.hint,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bg4,
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
