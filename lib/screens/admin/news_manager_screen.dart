import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/current_station_provider.dart';
import '../../providers/news_provider.dart';

final _adminNewsStreamProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final stationId = ref.watch(currentStationIdProvider) ?? 'lion';
  return FirebaseFirestore.instance
      .collection('news')
      .where('stationId', isEqualTo: stationId)
      .orderBy('publishedAt', descending: true)
      .snapshots()
      .map((s) => s.docs);
});

const _categories = [
  ('campus', 'Campus'),
  ('academic', 'Academic'),
  ('sports', 'Sports'),
  ('events', 'Events'),
  ('health', 'Health'),
  ('general', 'General'),
];

class NewsManagerScreen extends ConsumerWidget {
  const NewsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationId = ref.watch(currentStationIdProvider) ?? 'lion';
    final newsAsync = ref.watch(_adminNewsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('News Manager'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.lionGreen),
            tooltip: 'Add article',
            onPressed: () => _showForm(context, ref, stationId, null, null),
          ),
        ],
      ),
      body: newsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.lionGreen),
        ),
        error: (e, _) => Center(
          child: Text('Error loading news: $e',
              style: AppTextStyles.body.copyWith(color: AppColors.errorRed)),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined,
                      size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppDimensions.p16),
                  Text('No articles yet', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.p8),
                  Text(
                    'Tap + to publish your first article',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.p16),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.border1, height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final headline = data['headline'] as String? ?? '';
              final category = data['category'] as String? ?? 'general';
              final isFeatured = data['isFeatured'] as bool? ?? false;
              final ts = data['publishedAt'];
              final dateStr = ts is Timestamp
                  ? DateFormat('dd MMM yyyy, h:mm a').format(ts.toDate())
                  : '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.p8,
                    horizontal: AppDimensions.p4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFeatured
                        ? AppColors.lionGold.withValues(alpha: 0.15)
                        : AppColors.bg2,
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                  child: Icon(
                    isFeatured ? Icons.star_rounded : Icons.article_rounded,
                    color:
                        isFeatured ? AppColors.lionGold : AppColors.textMuted,
                    size: 20,
                  ),
                ),
                title: Text(
                  headline,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_categoryLabel(category)} · $dateStr',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      color: AppColors.electricTeal,
                      onPressed: () =>
                          _showForm(context, ref, stationId, doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      color: AppColors.errorRed,
                      onPressed: () => _confirmDelete(context, doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _categoryLabel(String cat) {
    for (final (value, label) in _categories) {
      if (value == cat) return label;
    }
    return cat;
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Article'),
        content: const Text(
            'This will permanently remove this article from the news feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('news').doc(docId).delete();
    }
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref,
    String stationId,
    String? docId,
    Map<String, dynamic>? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _NewsForm(
        stationId: stationId,
        docId: docId,
        existing: existing,
        onSaved: () => ref.invalidate(newsItemsProvider),
      ),
    );
  }
}

// ─── Add / Edit form ──────────────────────────────────────────────────────────

class _NewsForm extends StatefulWidget {
  final String stationId;
  final String? docId;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _NewsForm({
    required this.stationId,
    required this.docId,
    required this.existing,
    required this.onSaved,
  });

  @override
  State<_NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<_NewsForm> {
  final _headlineCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String _category = 'general';
  bool _isFeatured = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _headlineCtrl.text = d['headline'] as String? ?? '';
      _summaryCtrl.text = d['summary'] as String? ?? '';
      _imageUrlCtrl.text = d['imageUrl'] as String? ?? '';
      _category = d['category'] as String? ?? 'general';
      _isFeatured = d['isFeatured'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _summaryCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final headline = _headlineCtrl.text.trim();
    final summary = _summaryCtrl.text.trim();
    if (headline.isEmpty || summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Headline and summary are required'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final imageUrl = _imageUrlCtrl.text.trim();
      final payload = <String, dynamic>{
        'headline': headline,
        'summary': summary,
        'category': _category,
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'isFeatured': _isFeatured,
        'stationId': widget.stationId,
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.docId)
            .update({...payload, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        await FirebaseFirestore.instance.collection('news').add({
          ...payload,
          'publishedAt': FieldValue.serverTimestamp(),
          'readTimeMinutes': 3,
        });
      }

      widget.onSaved();
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
    final isEdit = widget.docId != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.p16,
        right: AppDimensions.p16,
        top: AppDimensions.p16,
        bottom: bottom + AppDimensions.p24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(isEdit ? 'Edit Article' : 'New Article',
                  style: AppTextStyles.h2),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p16),
          _field(_headlineCtrl, 'Headline *', maxLines: 2),
          const SizedBox(height: AppDimensions.p12),
          _field(_summaryCtrl, 'Summary *', maxLines: 4),
          const SizedBox(height: AppDimensions.p12),
          _field(_imageUrlCtrl, 'Image URL (optional)'),
          const SizedBox(height: AppDimensions.p12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.p16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: AppColors.bg2,
              underline: const SizedBox.shrink(),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c.$1,
                        child: Text(c.$2, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
          const SizedBox(height: AppDimensions.p8),
          SwitchListTile(
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            title: Text('Feature this article', style: AppTextStyles.body),
            subtitle: Text(
              'Shown prominently at the top of the news feed',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            activeThumbColor: AppColors.lionGold,
            activeTrackColor: AppColors.lionGold.withValues(alpha: 0.5),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppDimensions.p16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lionGreen,
                foregroundColor: AppColors.bg0,
                disabledBackgroundColor:
                    AppColors.lionGreen.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.r12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.bg0),
                    )
                  : Text(
                      isEdit ? 'Save Changes' : 'Publish Article',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.bg0),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTextStyles.body,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
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
        horizontal: AppDimensions.p16,
        vertical: AppDimensions.p12,
      ),
    );
  }
}
