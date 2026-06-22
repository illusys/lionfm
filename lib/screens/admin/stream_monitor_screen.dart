import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/audio_provider.dart';

enum _TestState { idle, testing, success, failure }

class StreamMonitorScreen extends ConsumerStatefulWidget {
  const StreamMonitorScreen({super.key});

  @override
  ConsumerState<StreamMonitorScreen> createState() => _StreamMonitorScreenState();
}

class _StreamMonitorScreenState extends ConsumerState<StreamMonitorScreen> {
  _TestState _testState = _TestState.idle;

  Future<void> _testStream(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No stream URL configured in Admin Settings'),
      ));
      return;
    }
    setState(() => _testState = _TestState.testing);
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player
          .setUrl(url, preload: true)
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _testState = _TestState.success);
    } catch (_) {
      if (mounted) setState(() => _testState = _TestState.failure);
    } finally {
      await player?.dispose();
    }
  }

  Future<void> _loadTestStream() async {
    const testUrl = 'https://stream.radioparadise.com/aac-128';
    try {
      await FirebaseFirestore.instance
          .collection('stream_config')
          .doc('current')
          .set({'streamUrl': testUrl}, SetOptions(merge: true));
      if (mounted) {
        setState(() => _testState = _TestState.idle);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Test stream URL saved — edit in Admin Settings'),
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

  @override
  Widget build(BuildContext context) {
    final streamStatus = ref.watch(streamStatusProvider);
    final urlAsync = ref.watch(liveStreamUrlProvider);
    final adminUser = ref.watch(adminUserProvider).valueOrNull;

    final currentUrl = urlAsync.valueOrNull ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Stream Monitor'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Read-only URL display card
          _SectionCard(
            title: 'CURRENT STREAM URL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urlAsync.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                      border: Border.all(color: AppColors.border1),
                    ),
                    child: Text(
                      currentUrl.isEmpty ? '(no URL configured)' : currentUrl,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: currentUrl.isEmpty
                            ? AppColors.textMuted
                            : AppColors.electricTeal,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'To change the URL, go to Admin Settings.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testState == _TestState.testing
                            ? null
                            : () => _testStream(currentUrl),
                        icon: _testState == _TestState.testing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _testState == _TestState.success
                                    ? Icons.check_circle_rounded
                                    : _testState == _TestState.failure
                                        ? Icons.cancel_rounded
                                        : Icons.play_circle_outline_rounded,
                                size: 16,
                                color: _testStateColor(_testState),
                              ),
                        label: Text(
                          _testState == _TestState.testing
                              ? 'Testing…'
                              : _testState == _TestState.success
                                  ? 'Reachable'
                                  : _testState == _TestState.failure
                                      ? 'Unreachable'
                                      : 'Test Stream',
                          style: TextStyle(color: _testStateColor(_testState)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _testStateColor(_testState)),
                        ),
                      ),
                    ),
                    if (adminUser?.isSuperAdmin == true) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadTestStream,
                          icon: const Icon(Icons.science_rounded,
                              size: 16, color: AppColors.warningGold),
                          label: const Text(
                            'Load Test Stream',
                            style: TextStyle(
                                color: AppColors.warningGold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.warningGold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // Live status + metrics
          streamStatus.when(
            data: (status) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p20),
                  decoration: BoxDecoration(
                    color: status.isLive
                        ? AppColors.liveRed.withValues(alpha: 0.1)
                        : AppColors.bg2,
                    borderRadius: BorderRadius.circular(AppDimensions.r16),
                    border: Border.all(
                      color: status.isLive
                          ? AppColors.liveRed.withValues(alpha: 0.4)
                          : AppColors.border1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: status.isLive
                              ? AppColors.liveRed
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        status.isLive ? 'STREAM LIVE' : 'OFF AIR',
                        style: AppTextStyles.h2.copyWith(
                          color: status.isLive
                              ? AppColors.liveRed
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _MetricCard(
                        label: 'Listeners',
                        value: '${status.listenerCount}',
                        color: AppColors.lionGreen),
                    _MetricCard(
                        label: 'Bitrate',
                        value: '${status.streamBitrate}kbps',
                        color: AppColors.electricTeal),
                    const _MetricCard(
                        label: 'Uptime',
                        value: '—',
                        color: AppColors.lionGold),
                    const _MetricCard(
                        label: 'Latency',
                        value: '—',
                        color: AppColors.burntAmber),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Stream restart requested'))),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Restart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Emergency stop sent'))),
                        icon: const Icon(Icons.stop_rounded,
                            color: AppColors.liveRed),
                        label: const Text('Stop',
                            style: TextStyle(color: AppColors.liveRed)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e', style: AppTextStyles.body)),
          ),
        ],
      ),
    );
  }

  Color _testStateColor(_TestState state) {
    switch (state) {
      case _TestState.success:
        return AppColors.successGreen;
      case _TestState.failure:
        return AppColors.errorRed;
      default:
        return AppColors.electricTeal;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

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
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard(
      {required this.label, required this.value, required this.color});

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
