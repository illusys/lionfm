import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/show_model.dart';

class ShowDetailSheet extends StatelessWidget {
  final ShowModel show;

  const ShowDetailSheet({super.key, required this.show});

  static void present(BuildContext context, ShowModel show) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShowDetailSheet(show: show),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = show.getStatus(now);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.r20),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.p20,
            AppDimensions.p8,
            AppDimensions.p20,
            AppDimensions.p32,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimensions.p16),
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(AppDimensions.rFull),
                ),
              ),
            ),
            Text(show.title, style: AppTextStyles.h2),
            const SizedBox(height: 6),
            Text(
              '${show.timeRange} · ${show.hostName}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.p12),
            Wrap(
              spacing: 8,
              children: [
                _CategoryChip(show.category.name),
                if (status == ShowStatus.live)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.rFull),
                      border:
                          Border.all(color: AppColors.liveRed.withValues(alpha: 0.5)),
                    ),
                    child: Text('● LIVE',
                        style: AppTextStyles.badgeText
                            .copyWith(color: AppColors.liveRed, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            Text(
              show.description,
              style: AppTextStyles.body
                  .copyWith(height: 1.6, color: AppColors.textSecondary),
            ),
            if (show.tags.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.p16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: show.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface3,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.rFull),
                            border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.4)),
                          ),
                          child: Text('#$tag',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.electricBlue)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppDimensions.p24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Reminder set! We'll notify you 10 minutes before ${show.title}"),
                    ),
                  );
                },
                icon: const Text('🔔'),
                label: const Text('Set Reminder'),
              ),
            ),
            if (status == ShowStatus.live) ...[
              const SizedBox(height: AppDimensions.p12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Listen Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: AppColors.border2),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
