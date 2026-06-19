import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _uptimeTimer;
  Duration _uptime = Duration.zero;

  final _stats = {
    'Live now': '312',
    'Peak today': '1,024',
    'This week': '18,450',
    'Premium': '47',
  };

  final _activity = [
    ('2m ago', 'New listener joined from Enugu'),
    ('5m ago', 'Song request: Afrobeats Mix'),
    ('12m ago', 'Show started: Morning Vibes'),
    ('1h ago', 'Premium subscription: +1'),
    ('2h ago', 'Stream reconnected'),
  ];

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
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: _stats.entries.map((e) => Container(
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
          const SizedBox(height: AppDimensions.p16),

          // Activity feed
          _AdminCard(
            title: 'Recent Activity',
            child: Column(
              children: _activity.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(item.$1, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.$2, style: AppTextStyles.bodySmall)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
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
