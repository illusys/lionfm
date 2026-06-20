import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';

class StreamMonitorScreen extends ConsumerWidget {
  const StreamMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamStatus = ref.watch(streamStatusProvider);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Stream Monitor'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          streamStatus.when(
            data: (status) => Column(
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p20),
                  decoration: BoxDecoration(
                    color: status.isLive ? AppColors.liveRed.withValues(alpha: 0.1) : AppColors.bg2,
                    borderRadius: BorderRadius.circular(AppDimensions.r16),
                    border: Border.all(
                      color: status.isLive ? AppColors.liveRed.withValues(alpha: 0.4) : AppColors.border1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: status.isLive ? AppColors.liveRed : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        status.isLive ? 'STREAM LIVE' : 'OFF AIR',
                        style: AppTextStyles.h2.copyWith(
                          color: status.isLive ? AppColors.liveRed : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
                // Metrics
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _MetricCard(label: 'Listeners', value: '${status.listenerCount}', color: AppColors.lionGreen),
                    _MetricCard(label: 'Bitrate', value: '${status.streamBitrate}kbps', color: AppColors.electricTeal),
                    _MetricCard(label: 'Uptime', value: '99.2%', color: AppColors.lionGold),
                    _MetricCard(label: 'Latency', value: '1.2s', color: AppColors.burntAmber),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                // Controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stream restart requested')),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Restart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency stop sent')),
                        ),
                        icon: const Icon(Icons.stop_rounded, color: AppColors.liveRed),
                        label: const Text('Stop', style: TextStyle(color: AppColors.liveRed)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.body)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        ],
      ),
    );
  }
}
