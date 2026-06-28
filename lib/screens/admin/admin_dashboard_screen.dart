import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';
import '../../providers/admin_auth_provider.dart';


final _adminStatsProvider = StreamProvider<Map<String, String>>((ref) {
  final today = DateTime.now();
  final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return FirebaseFirestore.instance.collection('analytics').doc(key).snapshots().map((doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return {
      'Live now': '${(data['listeners'] as num?)?.toInt() ?? 0}',
      'Peak today': '${(data['peakConcurrent'] as num?)?.toInt() ?? 0}',
      'Requests': '${(data['requests'] as num?)?.toInt() ?? 0}',
      'Premium': '${(data['premiumPurchases'] as num?)?.toInt() ?? 0}',
    };
  });
});

final _activityProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance
      .collection('admin_audit_logs')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            return '${data['action'] ?? 'activity'} · ${data['targetPath'] ?? 'system'}';
          }).toList());
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _uptimeTimer;
  Duration _uptime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _uptime += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _uptimeTimer.cancel();
    super.dispose();
  }

  String _formatUptime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final streamStatus = ref.watch(streamStatusProvider);
    final adminUser = ref.watch(adminUserProvider).valueOrNull;
    final statsAsync = ref.watch(_adminStatsProvider);
    final activityAsync = ref.watch(_activityProvider);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          if (adminUser != null) ...[
            _AdminBadge(adminUser: adminUser),
            const SizedBox(width: AppDimensions.p8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(streamStatusProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Stream status card
          _AdminCard(
            title: 'Stream Status',
            child: streamStatus.when(
              data: (status) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: status.isLive ? AppColors.liveRed : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.isLive ? 'LIVE' : 'OFF-AIR',
                        style: AppTextStyles.liveLabel.copyWith(
                          color: status.isLive ? AppColors.liveRed : AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text('Uptime: ${_formatUptime(_uptime)}', style: AppTextStyles.mono),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${status.listenerCount} listeners · ${status.streamBitrate}kbps',
                      style: AppTextStyles.bodySmall),
                  Text(status.currentShowTitle, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reconnect signal sent')),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reconnect Stream'),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: AppTextStyles.caption),
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // Stats grid
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Stats unavailable: $e', style: AppTextStyles.caption),
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
              children: stats.entries.map((e) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(AppDimensions.r12),
                  border: Border.all(color: AppColors.borderGreen, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: AppTextStyles.caption),
                    Text(e.value, style: AppTextStyles.h3.copyWith(color: AppColors.lionGold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // Activity feed
          _AdminCard(
            title: 'Recent Activity',
            child: activityAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Activity unavailable: $e', style: AppTextStyles.caption),
              data: (items) => Column(
                children: (items.isEmpty ? ['No recent admin activity'] : items).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item, style: AppTextStyles.bodySmall)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  final AdminUser adminUser;
  const _AdminBadge({required this.adminUser});

  Color get _roleColor {
    switch (adminUser.role) {
      case AdminRole.platformOwner: return AppColors.lionGold;
      case AdminRole.superAdmin: return AppColors.lionGreen;
      case AdminRole.stationManager: return AppColors.electricTeal;
      case AdminRole.broadcaster: return AppColors.warningGold;
      case AdminRole.unnAdmin: return const Color(0xFF4B8EFF);
      case AdminRole.none: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(adminUser.displayName,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.rFull),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            AdminUser.roleDisplayName(adminUser.role),
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _AdminCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          child,
        ],
      ),
    );
  }
}
