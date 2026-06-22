import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

/// Returns true when [e] is a Firestore "index still building" error.
/// These come back as FAILED_PRECONDITION from the backend.
bool isIndexBuildingError(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('failed_precondition') ||
      msg.contains('failed-precondition') ||
      (msg.contains('index') && msg.contains('build'));
}

/// Drop-in replacement for raw error text when a Firestore index isn't ready.
class IndexBuildingPlaceholder extends StatelessWidget {
  final bool compact;
  const IndexBuildingPlaceholder({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
            SizedBox(width: 10),
            Text('Setting up… try again in a moment.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Setting up…', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'The database index is still building.\nTry again in a moment.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
