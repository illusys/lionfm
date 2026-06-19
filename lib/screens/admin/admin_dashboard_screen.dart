import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // PIN gate
  bool _authenticated = false;
  final _pinCtrl = TextEditingController();
  String? _pinError;

  // Stream uptime counter
  late Timer _uptimeTimer;
  Duration _uptime = Duration.zero;

  // Notification sender
  String _notifType = 'LIVE_NOW';
  final _notifMsgCtrl = TextEditingController();
  String _notifAudience = 'All';

  // Stream override
  final _overrideCtrl = TextEditingController();

  // Mock stats
  final _stats = {
    'Live now': '312',
    'Peak today': '1,024',
    'Total this week': '18,450',
    'Premium subscribers': '47',
  };

  @override
  void initState() {
    super.initState();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _authenticated) {
        setState(() => _uptime += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _uptimeTimer.cancel();
    _pinCtrl.dispose();
    _notifMsgCtrl.dispose();
    _overrideCtrl.dispose();
    super.dispose();
  }

  void _checkPin() {
    if (_pinCtrl.text == AppStrings.defaultAdminPin) {
      setState(() {
        _authenticated = true;
        _pinError = null;
      });
    } else {
      setState(() => _pinError = 'Incorrect PIN');
    }
  }

  String _formatUptime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) return _buildPinGate();
    return _buildDashboard();
  }

  Widget _buildPinGate() {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(title: const Text('Admin Access')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppDimensions.p20),
              Text('Enter Admin PIN',
                  style: AppTextStyles.h2),
              const SizedBox(height: AppDimensions.p20),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: AppTextStyles.h1,
                decoration: InputDecoration(
                  errorText: _pinError,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppDimensions.p20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkPin,
                  child: const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final streamStatus = ref.watch(streamStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(streamStatusProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(streamStatusProvider),
        color: AppColors.amberGold,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.p16),
          children: [
            // Stream status card
            _SectionCard(
              title: 'Stream Status',
              child: streamStatus.when(
                data: (status) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status.isLive
                                ? AppColors.liveRed
                                : AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.isLive ? 'LIVE' : 'OFF-AIR',
                          style: AppTextStyles.liveLabel.copyWith(
                            color: status.isLive
                                ? AppColors.liveRed
                                : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Uptime: ${_formatUptime(_uptime)}',
                          style: AppTextStyles.mono,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${status.listenerCount} listeners · ${status.streamBitrate}kbps',
                        style: AppTextStyles.bodySmall),
                    Text(status.currentShowTitle,
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reconnect signal sent to Ant Media Server')),
                        );
                      },
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

            // Analytics grid
            _SectionCard(
              title: 'Listener Analytics',
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: _stats.entries.map((e) => Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: AppTextStyles.caption),
                      Text(e.value,
                          style: AppTextStyles.h3.copyWith(
                              color: AppColors.amberGold)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.p16),

            // Push notification sender
            _SectionCard(
              title: 'Send Push Notification',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _notifType,
                    dropdownColor: AppColors.surface2,
                    decoration: const InputDecoration(labelText: 'Type'),
                    onChanged: (v) => setState(() => _notifType = v!),
                    items: ['LIVE_NOW', 'BREAKING_NEWS', 'SPECIAL_EVENT']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notifMsgCtrl,
                    maxLength: 100,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _notifAudience,
                    dropdownColor: AppColors.surface2,
                    decoration: const InputDecoration(labelText: 'Send to'),
                    onChanged: (v) => setState(() => _notifAudience = v!),
                    items: ['All', 'Premium', 'show_alerts']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_notifMsgCtrl.text.isEmpty) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notification sent to $_notifAudience: ${_notifMsgCtrl.text}',
                            ),
                          ),
                        );
                        _notifMsgCtrl.clear();
                      },
                      child: const Text('Send Notification'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p16),

            // Schedule override
            _SectionCard(
              title: 'Schedule Override',
              child: Column(
                children: [
                  TextField(
                    controller: _overrideCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Currently on air (override)',
                      hintText: 'e.g. Special Broadcast — Convocation Live',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Override set: ${_overrideCtrl.text.isEmpty ? "(cleared)" : _overrideCtrl.text}',
                            ),
                          ),
                        );
                      },
                      child: const Text('Apply Override'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        color: AppColors.surface2,
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
