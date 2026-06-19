import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class NotificationSenderScreen extends StatefulWidget {
  const NotificationSenderScreen({super.key});
  @override
  State<NotificationSenderScreen> createState() => _NotificationSenderScreenState();
}

class _NotificationSenderScreenState extends State<NotificationSenderScreen> {
  String _notifType = 'LIVE_NOW';
  String _audience = 'All';
  final _msgCtrl = TextEditingController();

  final _history = [
    ('2h ago', 'LIVE_NOW', 'Morning Vibes is now live!', 'All', '1,247'),
    ('1d ago', 'BREAKING_NEWS', 'UNN Senate elections results out', 'All', '2,103'),
    ('3d ago', 'SPECIAL_EVENT', 'Convocation live coverage starting', 'Premium', '47'),
  ];

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Notifications'), automaticallyImplyLeading: false),
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
                  value: _notifType,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(labelText: 'Type'),
                  onChanged: (v) => setState(() => _notifType = v!),
                  items: ['LIVE_NOW', 'BREAKING_NEWS', 'SPECIAL_EVENT']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgCtrl,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _audience,
                  dropdownColor: AppColors.bg3,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  onChanged: (v) => setState(() => _audience = v!),
                  items: ['All', 'Premium', 'show_alerts']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.p16),
                ElevatedButton(
                  onPressed: () {
                    if (_msgCtrl.text.isEmpty) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sent to $_audience: ${_msgCtrl.text}')),
                    );
                    _msgCtrl.clear();
                  },
                  child: const Text('Send Notification'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p16),

          // History
          Text('HISTORY', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p8),
          ..._history.map((h) => Container(
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
                    Text(h.$2, style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal)),
                    const Spacer(),
                    Text(h.$1, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(h.$3, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text('${h.$4} · ${h.$5} delivered', style: AppTextStyles.caption),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
