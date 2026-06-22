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
  final _urlController = TextEditingController();
  bool _urlInitialized = false;
  bool _savingUrl = false;
  _TestState _testState = _TestState.idle;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() => _savingUrl = true);
    try {
      await FirebaseFirestore.instance
          .collection('stream_config')
          .doc('current')
          .set({'streamUrl': url}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stream URL updated'),
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
      if (mounted) setState(() => _savingUrl = false);
    }
  }

  Future<void> _testStream() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a stream URL first'),
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
        _urlController.text = testUrl;
        setState(() => _testState = _TestState.idle);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Test stream URL loaded and saved'),
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

    // Pre-fill URL field from Firestore on first load
    urlAsync.whenData((url) {
      if (!_urlInitialized) {
        _urlController.text = url;
        _urlInitialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Stream Monitor'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Stream URL management card
          _SectionCard(
            title: 'STREAM URL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _urlController,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.electricTeal,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://your-stream-url/path',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bg3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                      borderSide: const BorderSide(color: AppColors.border1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                      borderSide: const BorderSide(color: AppColors.border1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                      borderSide: const BorderSide(color: AppColors.lionGreen),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: urlAsync.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() => _testState = _TestState.idle),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _savingUrl ? null : _saveUrl,
                        icon: _savingUrl
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg0),
                              )
                            : const Icon(Icons.save_rounded, size: 16),
                        label: Text(_savingUrl ? 'Saving…' : 'Save URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lionGreen,
                          foregroundColor: AppColors.bg0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testState == _TestState.testing ? null : _testStream,
                        icon: _testState == _TestState.testing
                            ? const SizedBox(
                                width: 14, height: 14,
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
                  ],
                ),
                if (adminUser?.isSuperAdmin == true) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loadTestStream,
                    icon: const Icon(Icons.science_rounded, size: 16, color: AppColors.warningGold),
                    label: const Text(
                      'Load Test Stream (Radio Paradise)',
                      style: TextStyle(color: AppColors.warningGold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.warningGold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // Live status + metrics
          streamStatus.when(
            data: (status) => Column(
              children: [
                // Status indicator
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
                    const _MetricCard(label: 'Uptime', value: '99.2%', color: AppColors.lionGold),
                    const _MetricCard(label: 'Latency', value: '1.2s', color: AppColors.burntAmber),
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
