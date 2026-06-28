import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/request_model.dart';
import '../../providers/current_station_provider.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _statusFilterProvider = StateProvider<String?>((ref) => null); // null = all

final _requestsStreamProvider = StreamProvider<List<RequestModel>>((ref) {
  final stationId = ref.watch(currentStationIdProvider);
  return FirebaseFirestore.instance
      .collection('requests')
      .where('stationId', isEqualTo: stationId)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => RequestModel.fromFirestore(d)).toList());
});

final _filteredRequestsProvider = Provider<AsyncValue<List<RequestModel>>>((ref) {
  final allAsync = ref.watch(_requestsStreamProvider);
  final filter = ref.watch(_statusFilterProvider);
  return allAsync.whenData((list) {
    if (filter == null) return list;
    return list.where((r) => r.status.name == filter).toList();
  });
});

final _pendingCountProvider = Provider<int>((ref) {
  final all = ref.watch(_requestsStreamProvider).valueOrNull ?? [];
  return all.where((r) => r.status == RequestStatus.pending).length;
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class RequestQueueScreen extends ConsumerWidget {
  const RequestQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(_pendingCountProvider);
    final filter = ref.watch(_statusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Request Queue'),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(AppDimensions.rFull),
                ),
                child: Text(
                  '$pendingCount',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.bg0, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter tabs
          _FilterTabs(selected: filter),
          const Divider(height: 1, color: AppColors.border1),
          Expanded(child: _RequestList()),
        ],
      ),
    );
  }
}

class _FilterTabs extends ConsumerWidget {
  final String? selected;
  const _FilterTabs({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [
      (null, 'All'),
      ('pending', 'Pending'),
      ('acknowledged', 'Acknowledged'),
      ('played', 'Played'),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 8),
        children: tabs.map((t) {
          final isSelected = t.$1 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(_statusFilterProvider.notifier).state = t.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.greenTealGradient : null,
                  color: isSelected ? null : AppColors.bg2,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.rFull),
                  border: Border.all(
                    color:
                        isSelected ? Colors.transparent : AppColors.border1,
                  ),
                ),
                child: Text(
                  t.$2,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.bg0
                          : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_filteredRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e', style: AppTextStyles.body)),
      data: (requests) {
        // Sort: premium first, then by date
        final sorted = [...requests]
          ..sort((a, b) {
            if (a.isPremium != b.isPremium) {
              return a.isPremium ? -1 : 1;
            }
            return b.submittedAt.compareTo(a.submittedAt);
          });

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text('No requests', style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.p16),
          itemCount: sorted.length,
          itemBuilder: (_, i) => _RequestCard(request: sorted[i]),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isType = request.type;
    final statusColor = switch (request.status) {
      RequestStatus.pending => AppColors.warningGold,
      RequestStatus.acknowledged => AppColors.electricTeal,
      RequestStatus.played => AppColors.lionGreen,
      RequestStatus.skipped => AppColors.textMuted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: request.isPremium
            ? AppColors.lionGold.withValues(alpha: 0.07)
            : AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: request.isPremium
              ? AppColors.lionGold.withValues(alpha: 0.4)
              : AppColors.border1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isType == RequestType.song
                      ? Icons.music_note_rounded
                      : isType == RequestType.shoutout
                          ? Icons.record_voice_over_rounded
                          : Icons.mic_rounded,
                  color: AppColors.lionGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _mainText(request),
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (request.isPremium)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lionGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.rFull),
                            ),
                            child: Text('⭐ Premium',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.lionGold)),
                          ),
                      ],
                    ),
                    Text(
                      '${request.requesterName} · ${DateFormat('h:mm a').format(request.submittedAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.rFull),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: AppTextStyles.caption
                      .copyWith(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          if (request.message?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              request.message!,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          // Action row
          if (request.status == RequestStatus.pending ||
              request.status == RequestStatus.acknowledged)
            Row(
              children: [
                if (request.status == RequestStatus.pending)
                  _ActionChip(
                    label: 'Acknowledge',
                    color: AppColors.electricTeal,
                    onTap: () => _updateStatus(
                        request.id, RequestStatus.acknowledged),
                  ),
                if (request.status != RequestStatus.played) ...[
                  const SizedBox(width: 8),
                  _ActionChip(
                    label: 'Mark Played',
                    color: AppColors.lionGreen,
                    onTap: () =>
                        _updateStatus(request.id, RequestStatus.played),
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    label: 'Skip',
                    color: AppColors.textMuted,
                    onTap: () =>
                        _updateStatus(request.id, RequestStatus.skipped),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => _deleteRequest(context, request.id),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.errorRed),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _mainText(RequestModel r) {
    if (r.type == RequestType.song) {
      final song = r.songTitle ?? '';
      final artist = r.artistName ?? '';
      return song.isNotEmpty
          ? (artist.isNotEmpty ? '$song — $artist' : song)
          : 'Song Request';
    } else if (r.type == RequestType.shoutout) {
      return 'Shoutout: ${r.message ?? ''}';
    }
    return r.showConceptName ?? 'Show Pitch';
  }

  String _statusLabel(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.acknowledged:
        return 'ACK\'D';
      case RequestStatus.played:
        return 'PLAYED';
      case RequestStatus.skipped:
        return 'SKIPPED';
    }
  }

  void _updateStatus(String id, RequestStatus status) {
    FirebaseFirestore.instance
        .collection('requests')
        .doc(id)
        .update({'status': status.name});
  }

  void _deleteRequest(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Request'),
        content: const Text('Delete this request permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('requests')
                  .doc(id)
                  .delete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(color: color)),
      ),
    );
  }
}
