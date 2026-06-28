import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/audio_ad_model.dart';
import '../../data/models/direct_banner_ad_model.dart';
import '../../providers/current_station_provider.dart';
import '../../widgets/common/index_building_placeholder.dart';

final _bannerAdsProvider = StreamProvider<List<DirectBannerAd>>((ref) {
  final stationId = ref.watch(currentStationIdProvider) ?? 'lion';
  return FirebaseFirestore.instance
      .collection('ads')
      .where('stationId', isEqualTo: stationId)
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((s) => s.docs
          .where((d) => (d.data()['type'] as String?) != 'audio_instream')
          .map((d) => DirectBannerAd.fromFirestore(d))
          .toList());
});

final _audioAdsProvider = StreamProvider<List<AudioAdModel>>((ref) {
  final stationId = ref.watch(currentStationIdProvider) ?? 'lion';
  return FirebaseFirestore.instance
      .collection('ads')
      .where('stationId', isEqualTo: stationId)
      .where('type', isEqualTo: 'audio_instream')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AudioAdModel.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList());
});

const _bannerPlacements = [
  'home_mid',
  'podcasts',
  'news_top',
  'schedule_bottom',
  'interstitial',
];

const _audioPlacements = ['preroll', 'midroll', 'liveBreak'];
const _audioDurations = [15, 30, 45, 60];

class AdManagerScreen extends ConsumerStatefulWidget {
  const AdManagerScreen({super.key});

  @override
  ConsumerState<AdManagerScreen> createState() => _AdManagerScreenState();
}

class _AdManagerScreenState extends ConsumerState<AdManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Ad Manager'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Banner Ads'),
            Tab(text: 'Audio In-Stream'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabs.index == 0
            ? _showCreateBannerSheet(context)
            : _showCreateAudioAdSheet(context),
        backgroundColor: AppColors.lionGreen,
        foregroundColor: AppColors.bg0,
        icon: const Icon(Icons.add),
        label: Text(_tabs.index == 0 ? 'Banner Ad' : 'Audio Ad'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _BannerAdsTab(),
          _AudioAdsTab(),
        ],
      ),
    );
  }

  void _showCreateBannerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _CreateAdSheet(stationId: ref.read(currentStationIdProvider) ?? 'lion'),
    );
  }

  void _showCreateAudioAdSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _CreateAudioAdSheet(stationId: ref.read(currentStationIdProvider) ?? 'lion'),
    );
  }
}

// ─── Banner Ads tab ───────────────────────────────────────────────────────────

class _BannerAdsTab extends ConsumerWidget {
  const _BannerAdsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(_bannerAdsProvider);

    return adsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => isIndexBuildingError(e)
          ? const IndexBuildingPlaceholder()
          : Center(child: Text('Error: $e', style: AppTextStyles.body)),
      data: (ads) {
        final active = ads.where((a) => a.status == 'active').length;
        final scheduled = ads.where((a) => a.status == 'scheduled').length;

        return ListView(
          padding: const EdgeInsets.all(AppDimensions.p16),
          children: [
            Row(children: [
              _AdStat(label: 'Active', value: '$active', color: AppColors.lionGreen),
              const SizedBox(width: 12),
              _AdStat(label: 'Scheduled', value: '$scheduled', color: AppColors.electricTeal),
              const SizedBox(width: 12),
              _AdStat(label: 'Total', value: '${ads.length}', color: AppColors.lionGold),
            ]),
            const SizedBox(height: AppDimensions.p16),
            if (ads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('No banner ads yet', style: TextStyle(color: AppColors.textMuted)),
                  ]),
                ),
              )
            else ...[
              Text('ALL CAMPAIGNS', style: AppTextStyles.label),
              const SizedBox(height: AppDimensions.p8),
              ...ads.map((ad) => _AdCard(
                    ad: ad,
                    onDelete: () => _deleteAd(context, ad.id),
                  )),
            ],
          ],
        );
      },
    );
  }

  Future<void> _deleteAd(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Ad'),
        content: const Text('Delete this ad campaign permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('ads').doc(id).delete();
    }
  }
}

// ─── Audio In-Stream tab ──────────────────────────────────────────────────────

class _AudioAdsTab extends ConsumerWidget {
  const _AudioAdsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(_audioAdsProvider);

    return adsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => isIndexBuildingError(e)
          ? const IndexBuildingPlaceholder()
          : Center(child: Text('Error: $e', style: AppTextStyles.body)),
      data: (ads) {
        if (ads.isEmpty) {
          return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.volume_up_outlined, size: 56, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text('No audio ads yet', style: TextStyle(color: AppColors.textMuted)),
              SizedBox(height: 8),
              Text('Tap + to add an in-stream audio ad.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.p16),
          itemCount: ads.length,
          itemBuilder: (_, i) => _AudioAdCard(
            ad: ads[i],
            onDelete: () => _deleteAd(context, ads[i].id),
          ),
        );
      },
    );
  }

  Future<void> _deleteAd(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Audio Ad'),
        content: const Text('Delete this audio ad permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('ads').doc(id).delete();
    }
  }
}

class _AudioAdCard extends StatelessWidget {
  final AudioAdModel ad;
  final VoidCallback onDelete;
  const _AudioAdCard({required this.ad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = ad.isCurrentlyActive;
    final statusColor = isActive ? AppColors.lionGreen : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.rFull),
              ),
              child: Text(isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AppTextStyles.caption.copyWith(color: statusColor)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.electricTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.rFull),
              ),
              child: Text(ad.placement.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.textMuted),
              onPressed: onDelete,
            ),
          ]),
          const SizedBox(height: 6),
          Text(ad.advertiserName, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('${ad.durationSec}s', style: AppTextStyles.caption),
            const SizedBox(width: 12),
            Text(
              '${DateFormat('MMM d').format(ad.startDate)} – ${DateFormat('MMM d, y').format(ad.endDate)}',
              style: AppTextStyles.caption,
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.play_arrow_outlined, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('${ad.impressions} impressions', style: AppTextStyles.caption),
            const SizedBox(width: 12),
            const Icon(Icons.check_circle_outline, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('${ad.completions} completions', style: AppTextStyles.caption),
            if (ad.impressions > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${(ad.completions / ad.impressions * 100).toStringAsFixed(0)}% completion',
                style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ─── Create Audio Ad Sheet ────────────────────────────────────────────────────

class _CreateAudioAdSheet extends StatefulWidget {
  final String stationId;
  const _CreateAudioAdSheet({required this.stationId});

  @override
  State<_CreateAudioAdSheet> createState() => _CreateAudioAdSheetState();
}

class _CreateAudioAdSheetState extends State<_CreateAudioAdSheet> {
  final _advertiserCtrl = TextEditingController();
  final _clickUrlCtrl = TextEditingController();
  int _durationSec = 30;
  String _placement = _audioPlacements.first;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _saving = false;
  String? _audioUrl;
  String? _audioStatus;
  String? _imageUrl;
  String? _imageStatus;

  @override
  void dispose() {
    _advertiserCtrl.dispose();
    _clickUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _audioStatus = 'Uploading…');
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('ads/audio/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putData(file.bytes!, SettableMetadata(contentType: 'audio/mpeg'));
      final url = await ref.getDownloadURL();
      setState(() {
        _audioUrl = url;
        _audioStatus = 'Uploaded: ${file.name}';
      });
    } catch (e) {
      setState(() => _audioStatus = 'Upload failed: $e');
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _imageStatus = 'Uploading…');
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('ads/images/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putData(
          file.bytes!, SettableMetadata(contentType: 'image/${file.extension ?? 'jpg'}'));
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url;
        _imageStatus = 'Uploaded ✓';
      });
    } catch (e) {
      setState(() => _imageStatus = 'Upload failed: $e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lionGreen,
            surface: AppColors.bg2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked; else _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_advertiserCtrl.text.trim().isEmpty) {
      _snack('Advertiser name is required');
      return;
    }
    if (_audioUrl == null) {
      _snack('Please upload an MP3 audio file');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _snack('End date must be after start date');
      return;
    }

    setState(() => _saving = true);
    try {
      final ad = AudioAdModel(
        id: '',
        advertiserName: _advertiserCtrl.text.trim(),
        durationSec: _durationSec,
        audioUrl: _audioUrl!,
        companionImageUrl: _imageUrl,
        clickUrl: _clickUrlCtrl.text.trim().isEmpty ? null : _clickUrlCtrl.text.trim(),
        placement: _placement,
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
      );
      await FirebaseFirestore.instance.collection('ads').add({
        ...ad.toFirestore(),
        'stationId': widget.stationId,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Audio In-Stream Ad', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text('Free listeners only — premium users skip ads.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),

          _label('Advertiser Name'),
          TextField(
            controller: _advertiserCtrl,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
                hintText: 'e.g. UNN Bookshop', filled: true, fillColor: AppColors.bg3),
          ),
          const SizedBox(height: 12),

          _label('Audio File (MP3)'),
          GestureDetector(
            onTap: _pickAudio,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.audio_file_outlined,
                    color: _audioUrl != null ? AppColors.successGreen : AppColors.electricTeal,
                    size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _audioStatus ?? 'Tap to upload MP3',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: _audioUrl != null
                            ? AppColors.successGreen
                            : AppColors.electricTeal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          _label('Duration Slot'),
          DropdownButtonFormField<int>(
            initialValue: _durationSec,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(filled: true, fillColor: AppColors.bg3),
            items: _audioDurations
                .map((d) => DropdownMenuItem(
                    value: d, child: Text('${d}s', style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (v) => setState(() => _durationSec = v!),
          ),
          const SizedBox(height: 12),

          _label('Placement'),
          DropdownButtonFormField<String>(
            initialValue: _placement,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(filled: true, fillColor: AppColors.bg3),
            items: _audioPlacements
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (v) => setState(() => _placement = v!),
          ),
          const SizedBox(height: 12),

          _label('Companion Image (optional)'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.image_outlined,
                    color: _imageUrl != null ? AppColors.successGreen : AppColors.textMuted,
                    size: 16),
                const SizedBox(width: 8),
                Text(
                  _imageStatus ?? 'Upload companion image',
                  style: AppTextStyles.caption.copyWith(
                      color: _imageUrl != null ? AppColors.successGreen : AppColors.textMuted),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          _label('Click URL (optional)'),
          TextField(
            controller: _clickUrlCtrl,
            keyboardType: TextInputType.url,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
                hintText: 'https://…', filled: true, fillColor: AppColors.bg3),
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: _DatePickerTile(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerTile(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false)),
            ),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Text('Active', style: AppTextStyles.body),
            const Spacer(),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeThumbColor: AppColors.lionGreen,
            ),
          ]),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lionGreen, foregroundColor: AppColors.bg0),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg0))
                : const Text('Create Audio Ad'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.label));
}

// ─── Banner Ad card ───────────────────────────────────────────────────────────

class _AdCard extends StatelessWidget {
  final DirectBannerAd ad;
  final VoidCallback onDelete;
  const _AdCard({required this.ad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ad.status) {
      'active' => AppColors.lionGreen,
      'scheduled' => AppColors.electricTeal,
      'expired' => AppColors.textMuted,
      _ => AppColors.errorRed,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ad.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    ad.imageUrl,
                    width: 60,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 30,
                      color: AppColors.bg3,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 30,
                  color: AppColors.bg3,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined,
                      size: 16, color: AppColors.textMuted),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.advertiserName, style: AppTextStyles.bodyMedium),
                    Text(
                      '${ad.format.label} · ${ad.placement}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.rFull),
                ),
                child: Text(
                  ad.status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: statusColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${DateFormat('MMM d').format(ad.startDate)} – ${DateFormat('MMM d, y').format(ad.endDate)}',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              Icon(Icons.visibility_outlined,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${ad.impressions}', style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Icon(Icons.touch_app_outlined,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${ad.clicks}', style: AppTextStyles.caption),
              if (ad.impressions > 0) ...[
                const SizedBox(width: 6),
                Text(
                  'CTR: ${(ad.clicks / ad.impressions * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.electricTeal),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AdStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AdStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Create Ad Sheet ──────────────────────────────────────────────────────────

class _CreateAdSheet extends StatefulWidget {
  final String stationId;
  const _CreateAdSheet({required this.stationId});

  @override
  State<_CreateAdSheet> createState() => _CreateAdSheetState();
}

class _CreateAdSheetState extends State<_CreateAdSheet> {
  final _advertiserCtrl = TextEditingController();
  final _clickUrlCtrl = TextEditingController();
  IabAdFormat _format = IabAdFormat.mobileLeaderboard;
  String _placement = _bannerPlacements.first;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _saving = false;
  String? _uploadedImageUrl;
  String? _uploadStatus;

  @override
  void dispose() {
    _advertiserCtrl.dispose();
    _clickUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploadStatus = 'Uploading…');
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('ads/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putData(file.bytes!,
          SettableMetadata(contentType: 'image/${file.extension ?? 'png'}'));
      final url = await ref.getDownloadURL();
      setState(() {
        _uploadedImageUrl = url;
        _uploadStatus =
            'Uploaded ✓ (verify it matches ${_format.width.toInt()}×${_format.height.toInt()}px)';
      });
    } catch (e) {
      setState(() => _uploadStatus = 'Upload failed: $e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lionGreen,
            surface: AppColors.bg2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_advertiserCtrl.text.trim().isEmpty) {
      _snack('Advertiser name is required');
      return;
    }
    if (_clickUrlCtrl.text.trim().isEmpty) {
      _snack('Click-through URL is required');
      return;
    }
    if (_uploadedImageUrl == null) {
      _snack('Please upload an ad image');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _snack('End date must be after start date');
      return;
    }

    setState(() => _saving = true);
    try {
      final ad = DirectBannerAd(
        id: '',
        advertiserName: _advertiserCtrl.text.trim(),
        format: _format,
        imageUrl: _uploadedImageUrl!,
        clickUrl: _clickUrlCtrl.text.trim(),
        placement: _placement,
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
      );
      await FirebaseFirestore.instance.collection('ads').add({
        ...ad.toFirestore(),
        'stationId': widget.stationId,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          Text('Create Ad', style: AppTextStyles.h2),
          const SizedBox(height: 16),

          _label('Advertiser Name'),
          TextField(
            controller: _advertiserCtrl,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
                hintText: 'e.g. UNN Bookshop',
                filled: true,
                fillColor: AppColors.bg3),
          ),
          const SizedBox(height: 12),

          _label('Ad Format'),
          DropdownButtonFormField<IabAdFormat>(
            initialValue: _format,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(
                filled: true, fillColor: AppColors.bg3),
            items: IabAdFormat.values
                .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label, style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (v) => setState(() => _format = v!),
          ),
          const SizedBox(height: 12),

          _label('Image Upload'),
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_rounded,
                      color: AppColors.electricTeal, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _uploadStatus ?? 'Tap to upload image',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: _uploadedImageUrl != null
                              ? AppColors.successGreen
                              : AppColors.electricTeal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _label('Click-Through URL'),
          TextField(
            controller: _clickUrlCtrl,
            keyboardType: TextInputType.url,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
                hintText: 'https://advertiser.example.com',
                filled: true,
                fillColor: AppColors.bg3),
          ),
          const SizedBox(height: 12),

          _label('Placement'),
          DropdownButtonFormField<String>(
            initialValue: _placement,
            dropdownColor: AppColors.bg3,
            decoration: const InputDecoration(
                filled: true, fillColor: AppColors.bg3),
            items: _bannerPlacements
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (v) => setState(() => _placement = v!),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerTile(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text('Active', style: AppTextStyles.body),
              const Spacer(),
              Switch(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppColors.lionGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg0))
                : const Text('Create Ad'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerTile(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(color: AppColors.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(DateFormat('MMM d, yyyy').format(date),
                style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
