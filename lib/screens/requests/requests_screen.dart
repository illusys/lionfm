import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import 'widgets/show_pitch_form.dart';
import 'widgets/song_request_form.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.requestsTitle)),
      body: Column(
        children: [
          // Custom tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.p16,
              AppDimensions.p12,
              AppDimensions.p16,
              AppDimensions.p4,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.r10),
                border: Border.all(color: AppColors.border1),
              ),
              child: Row(
                children: [
                  _TabPill(
                    label: AppStrings.songRequestTab,
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabPill(
                    label: AppStrings.showPitchTab,
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == 0
                  ? const SongRequestForm(key: ValueKey('song'))
                  : const ShowPitchForm(key: ValueKey('pitch')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.unnDeepBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.r8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: selected ? AppColors.pureWhite : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
