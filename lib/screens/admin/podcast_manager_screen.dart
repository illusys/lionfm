import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class PodcastManagerScreen extends StatelessWidget {
  const PodcastManagerScreen({super.key});

  final _episodes = const [
    ('Morning Vibes EP.12', 'DJ Chukwuemeka', '45 min', '1.2k plays', '2d ago'),
    ('Campus Connect EP.8', 'Ngozi Adaeze', '30 min', '876 plays', '5d ago'),
    ('Tech Talk EP.3', 'Emeka Obi', '52 min', '643 plays', '1w ago'),
    ('Health Hour EP.6', 'Dr. Amaka', '28 min', '412 plays', '2w ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Podcast Manager'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload episode')),
        ),
        child: const Icon(Icons.upload_rounded),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.p16),
        itemCount: _episodes.length,
        itemBuilder: (_, i) {
          final ep = _episodes[i];
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.greenTealGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mic_rounded, color: AppColors.bg0, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ep.$1, style: AppTextStyles.bodyMedium),
                      Text(ep.$2, style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal)),
                      Row(
                        children: [
                          Text(ep.$3, style: AppTextStyles.caption),
                          const SizedBox(width: 8),
                          Text('·', style: AppTextStyles.caption),
                          const SizedBox(width: 8),
                          Text(ep.$4, style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(ep.$5, style: AppTextStyles.caption),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  color: AppColors.bg3,
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                  onSelected: (v) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$v: ${ep.$1}')),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                    const PopupMenuItem(value: 'Archive', child: Text('Archive')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
