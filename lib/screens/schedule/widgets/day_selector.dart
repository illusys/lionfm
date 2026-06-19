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
  final _scrollCtrl = ScrollController();

  static const _days = [
    ('Mon', 'Monday'),
    ('Tue', 'Tuesday'),
    ('Wed', 'Wednesday'),
    ('Thu', 'Thursday'),
    ('Fri', 'Friday'),
    ('Sat', 'Saturday'),
    ('Sun', 'Sunday'),
  ];

  int get _todayIndex => DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _todayIndex * (AppDimensions.dayPillWidth + 8),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDayProvider);

    return SizedBox(
      height: AppDimensions.dayPillHeight + 16,
      child: ListView.separated(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: 8),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (abbr, full) = _days[i];
          final isSelected = selected == full;
          final isToday = i == _todayIndex;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDayProvider.notifier).state = full;
              _scrollCtrl.animateTo(
                i * (AppDimensions.dayPillWidth + 8),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: AppDimensions.dayPillWidth,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.unnDeepBlue.withOpacity(0.5)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.electricBlue
                      : AppColors.border1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(abbr, style: AppTextStyles.label.copyWith(
                    color: isSelected ? AppColors.pureWhite : AppColors.textTertiary,
                  )),
                  const SizedBox(height: 2),
                  Text(
                    '${_dateForDay(i)}',
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18,
                      color: isSelected ? AppColors.pureWhite : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _dateForDay(int dayIndex) {
    final now = DateTime.now();
    final diff = dayIndex - (now.weekday - 1);
    return now.add(Duration(days: diff)).day;
  }
}
