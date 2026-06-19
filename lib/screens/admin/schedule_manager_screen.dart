import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class ScheduleManagerScreen extends StatefulWidget {
  const ScheduleManagerScreen({super.key});
  @override
  State<ScheduleManagerScreen> createState() => _ScheduleManagerScreenState();
}

class _ScheduleManagerScreenState extends State<ScheduleManagerScreen> {
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  int _selectedDay = 0;

  final _shows = [
    ('06:00', '08:00', 'Morning Vibes', 'DJ Chukwuemeka'),
    ('08:00', '10:00', 'Campus Connect', 'Ngozi Adaeze'),
    ('10:00', '12:00', 'Tech Talk', 'Emeka Obi'),
    ('12:00', '14:00', 'Midday Mix', 'Amaka Eze'),
    ('14:00', '16:00', 'Sports Hour', 'Chidi Nwosu'),
    ('16:00', '18:00', 'Evening Chill', 'Blessing Okeke'),
    ('18:00', '20:00', 'News & Views', 'Ify Obiora'),
    ('20:00', '22:00', 'Night Owls', 'Tunde Fashola'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Schedule Manager'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddShowDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Day tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _days.length,
              itemBuilder: (_, i) {
                final isSelected = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.greenTealGradient : null,
                      color: isSelected ? null : AppColors.bg2,
                      borderRadius: BorderRadius.circular(AppDimensions.rFull),
                      border: Border.all(color: isSelected ? Colors.transparent : AppColors.border1),
                    ),
                    child: Text(_days[i],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.bg0 : AppColors.textSecondary,
                      )),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.p16),
              itemCount: _shows.length,
              itemBuilder: (_, i) {
                final show = _shows[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.p8),
                  padding: const EdgeInsets.all(AppDimensions.p12),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(AppDimensions.r12),
                    border: Border.all(color: AppColors.border1),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(show.$1, style: AppTextStyles.mono.copyWith(color: AppColors.lionGreen)),
                          Text(show.$2, style: AppTextStyles.mono.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(width: AppDimensions.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(show.$3, style: AppTextStyles.bodyMedium),
                            Text(show.$4, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.liveRed),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShowDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Show', style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.p16),
            const TextField(decoration: InputDecoration(labelText: 'Show Title')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Host Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: TextField(decoration: InputDecoration(labelText: 'Start Time'))),
                const SizedBox(width: 12),
                const Expanded(child: TextField(decoration: InputDecoration(labelText: 'End Time'))),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Add Show'),
            ),
          ],
        ),
      ),
    );
  }
}
