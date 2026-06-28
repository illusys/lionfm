import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/current_station_provider.dart';

final _notifHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final stationId = ref.watch(currentStationIdProvider);
  return FirebaseFirestore.instance
      .collection('notification_queue')
      .where('stationId', isEqualTo: stationId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>(
            (d) => <String, dynamic>{'id': d.id, ...d.data()},
          )
          .toList());
});

class NotificationSenderScreen extends ConsumerStatefulWidget {
  const NotificationSenderScreen({super.key});

  @override
  ConsumerState<NotificationSenderScreen> createState() =>
      _NotificationSenderScreenState();
}

class _NotificationSenderScreenState
    extends ConsumerState<NotificationSenderScreen> {
  String _notifType = 'LIVE_NOW';
  String _audience = 'All';
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  String _audienceToTopic(String audience) {
    switch (audience) {
      case 'Premium':
        return 'premium_listeners';
      case 'Show Alerts':
        return 'show_alerts';
      default:
        return 'all_listeners';
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Message cannot be empty'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('notification_queue').add({
        'stationId': ref.read(currentStationIdProvider),
        'type': _notifType,
        'title': title.isEmpty ? _defaultTitle(_notifType) : title,
        'body': body,
        'topic': _audienceToTopic(_audience),
        'audience': _audience,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _titleCtrl.clear();
        _msgCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notification queued — sending now…'),
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
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'LIVE_NOW':
        return 'Lion FM is Live!';
      case 'BREAKING_NEWS':
        return 'Breaking News';
      default:
        return 'Lion FM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(_notifHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Send form
          Container(
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              border: Border.all(color: AppColors.border1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEND NOTIFICATION', style: AppTextStyles.label),
                const SizedBox(height: AppDimensions.p12),
                DropdownButtonFormField<String>(
                  initialValue: _notifType,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(labelText: 'Type'),
                  onChanged: (v) => setState(() => _notifType = v!),
                  items: ['LIVE_NOW', 'BREAKING_NEWS', 'SPECIAL_EVENT']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    hintText: _defaultTitle(_notifType),
                    hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgCtrl,
                  maxLength: 120,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  onChanged: (v) => setState(() => _audience = v!),
                  items: ['All', 'Premium', 'Show Alerts']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.p16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lionGreen,
                      foregroundColor: AppColors.bg0,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.bg0),
                          )
                        : const Text('Send Notification'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // History from Firestore
          Text('HISTORY', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error loading history: $e', style: AppTextStyles.caption),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.p24),
                    child: Text(
                      'No notifications sent yet.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                );
              }
              return Column(
                children: items.map((h) {
                  final status = h['status'] as String? ?? 'pending';
                  final statusColor = status == 'sent'
                      ? AppColors.successGreen
                      : status == 'failed'
                          ? AppColors.errorRed
                          : AppColors.warningGold;
                  final createdAt = h['createdAt'] as Timestamp?;
                  final timeStr = createdAt != null
                      ? _formatTs(createdAt.toDate())
                      : '—';
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
                            Text(
                              h['type'] as String? ?? '—',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.electricTeal),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppDimensions.rFull),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if ((h['title'] as String?)?.isNotEmpty == true)
                          Text(h['title'] as String, style: AppTextStyles.bodyMedium),
                        Text(h['body'] as String? ?? '—', style: AppTextStyles.body),
                        const SizedBox(height: 4),
                        Text(
                          '${h['audience'] ?? h['topic'] ?? '—'} · $timeStr',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTs(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
