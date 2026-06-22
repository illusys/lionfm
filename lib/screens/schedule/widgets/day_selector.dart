import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/schedule_provider.dart';

class DaySelector extends ConsumerStatefulWidget {
  const DaySelector({super.key});
  @override
  ConsumerState<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends ConsumerState<DaySelector> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now().weekday;
      final offset = (today - 1) * 64.0;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final selectedDay = ref.watch(selectedDayProvider);
    final today = DateTime.now().weekday;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: 7,
        itemBuilder: (_, index) {
          final dayIndex = index + 1; // 1=Mon … 7=Sun
          final dayName = days[index];
          final isSelected = dayName == selectedDay;
          final isToday = dayIndex == today;
          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = dayName,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.greenTealGradient : null,
                color: isSelected ? null : AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: isSelected ? null : Border.all(color: AppColors.border1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.substring(0, 3),
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.bg0 : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dayIndex',
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? AppColors.bg0 : AppColors.textPrimary,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.bg0 : AppColors.lionGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
