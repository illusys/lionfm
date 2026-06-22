import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/event_model.dart';
import '../../providers/events_provider.dart';

class EventsManagerScreen extends ConsumerWidget {
  const EventsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Events Manager'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.lionGreen,
        foregroundColor: AppColors.bg0,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: AppTextStyles.body)),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No events yet', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text('Tap + to create a live event.',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.p16),
            itemCount: events.length,
            itemBuilder: (_, i) => _EventTile(event: events[i]),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateEventSheet(),
    );
  }
}

// ─── Event list tile ──────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final EventModel event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p12),
      padding: const EdgeInsets.all(AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: event.isLive
              ? AppColors.liveRed.withValues(alpha: 0.5)
              : AppColors.border1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (event.isLive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.rFull),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  Expanded(
                    child: Text(event.title,
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, y · h:mm a').format(event.startTime),
                  style: AppTextStyles.caption,
                ),
                Text(
                  event.isFree
                      ? 'Free entry'
                      : '₦${NumberFormat('#,###').format(event.ticketPriceNGN)}',
                  style: AppTextStyles.caption.copyWith(
                      color: event.isFree
                          ? AppColors.successGreen
                          : AppColors.lionGold),
                ),
              ],
            ),
          ),
          // Toggle live
          Switch(
            value: event.isLive,
            onChanged: (v) => FirebaseFirestore.instance
                .collection('events')
                .doc(event.id)
                .update({'isLive': v}),
            activeTrackColor: AppColors.liveRed,
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted, size: 20),
            onPressed: () => _confirmDelete(context, event.id),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Event'),
        content: const Text('Delete this event permanently?'),
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
    if (ok == true) {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
    }
  }
}

// ─── Create event sheet ───────────────────────────────────────────────────────

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet();

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _streamUrlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime =
      DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isPremiumFree = true;
  bool _saving = false;
  String? _posterUrl;
  String? _posterStatus;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _streamUrlCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _posterStatus = 'Uploading…');
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('events/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putData(
          file.bytes!,
          SettableMetadata(
              contentType: 'image/${file.extension ?? 'jpg'}'));
      final url = await ref.getDownloadURL();
      setState(() {
        _posterUrl = url;
        _posterStatus = 'Uploaded ✓';
      });
    } catch (e) {
      setState(() => _posterStatus = 'Upload failed: $e');
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
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
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title is required');
      return;
    }
    if (_streamUrlCtrl.text.trim().isEmpty) {
      _snack('Stream URL is required');
      return;
    }
    if (_endTime.isBefore(_startTime)) {
      _snack('End time must be after start time');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final event = EventModel(
        id: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        posterUrl: _posterUrl,
        streamUrl: _streamUrlCtrl.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        ticketPriceNGN: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        isPremiumFree: _isPremiumFree,
        createdBy: uid,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('events')
          .add(event.toFirestore());
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
          Text('Create Event', style: AppTextStyles.h2),
          const SizedBox(height: 16),

          _label('Event Title'),
          _field(_titleCtrl, 'e.g. Theatre & Film Arts Gala Night'),
          const SizedBox(height: 12),

          _label('Description'),
          _field(_descCtrl, 'Brief description…', maxLines: 3),
          const SizedBox(height: 12),

          _label('Poster Image'),
          GestureDetector(
            onTap: _pickPoster,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius:
                    BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_rounded,
                      color: AppColors.electricTeal, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _posterStatus ?? 'Tap to upload poster',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: _posterUrl != null
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

          _label('HLS Stream URL'),
          _field(_streamUrlCtrl, 'https://stream.example.com/event.m3u8',
              keyboardType: TextInputType.url),
          const SizedBox(height: 12),

          _label('Ticket Price (₦) — 0 = Free'),
          _field(_priceCtrl, '0',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: _DateTile(
                label: 'Start',
                dt: _startTime,
                onTap: () => _pickDateTime(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateTile(
                label: 'End',
                dt: _endTime,
                onTap: () => _pickDateTime(isStart: false),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Text('Premium subscribers get free access',
                style: AppTextStyles.body),
            const Spacer(),
            Switch(
              value: _isPremiumFree,
              onChanged: (v) => setState(() => _isPremiumFree = v),
              activeTrackColor: AppColors.lionGreen,
            ),
          ]),
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
                : const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.label));

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        style: AppTextStyles.body,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.bg3,
        ),
      );
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime dt;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.dt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Text(DateFormat('MMM d, y · h:mm a').format(dt),
                style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
