import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class RequestQueueScreen extends StatelessWidget {
  const RequestQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(
          title: const Text('Request Queue'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.lionGreen,
            labelColor: AppColors.lionGreen,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [Tab(text: 'Song Requests'), Tab(text: 'Show Pitches')],
          ),
        ),
        body: TabBarView(
          children: [
            _SongRequestsTab(),
            _ShowPitchesTab(),
          ],
        ),
      ),
    );
  }
}

class _SongRequestsTab extends StatelessWidget {
  final _requests = [
    ('Chidi M.', 'Essence — Wizkid ft. Tems', 'Campus FM listener', '2m ago'),
    ('Amaka O.', 'Ye — Burna Boy', 'Premium listener', '5m ago'),
    ('Tunde A.', 'Calm Down — Rema', 'Guest', '10m ago'),
    ('Ngozi E.', 'Peru — Fireboy DML', 'Campus FM listener', '15m ago'),
    ('Emeka C.', 'Mnike — Tyler ICU', 'Guest', '22m ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.p16),
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final r = _requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(AppDimensions.r12),
            border: Border.all(color: AppColors.border1),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.music_note_rounded, color: AppColors.lionGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$2, style: AppTextStyles.bodyMedium),
                    Text('${r.$1} · ${r.$3}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(r.$4, style: AppTextStyles.caption),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.lionGreen, size: 22),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request approved: ${r.$2}')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShowPitchesTab extends StatelessWidget {
  final _pitches = [
    ('Blessing O.', 'Health & Wellness Hour', 'Weekly show on campus health tips', 'Pending'),
    ('Ify C.', 'Tech Startup Stories', 'Interviews with UNN student founders', 'Review'),
    ('Kelechi A.', 'Spoken Word Sundays', 'Poetry and spoken word performances', 'Approved'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.p16),
      itemCount: _pitches.length,
      itemBuilder: (_, i) {
        final p = _pitches[i];
        final statusColor = p.$4 == 'Approved' ? AppColors.lionGreen
            : p.$4 == 'Pending' ? AppColors.lionGold : AppColors.electricTeal;
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
                  Text(p.$2, style: AppTextStyles.bodyMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.rFull),
                    ),
                    child: Text(p.$4, style: AppTextStyles.caption.copyWith(color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('by ${p.$1}', style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal)),
              Text(p.$3, style: AppTextStyles.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
