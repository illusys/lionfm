import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';

/// Shown in both the listener and admin chat screens when Firestore returns a
/// 'failed-precondition' error while a required index is still being built.
///
/// The index typically builds within 60 seconds of the first deploy. Riverpod's
/// StreamProvider will automatically re-emit once the stream reconnects after
/// the index is ready — no manual refresh is needed.
class ChatIndexBuildingView extends StatelessWidget {
  const ChatIndexBuildingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.lionGreen,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: AppDimensions.p20),
            Text('Setting up chat…', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.p8),
            Text(
              'We\'re preparing the message database.\n'
              'This usually takes less than a minute.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.p16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.p12, vertical: AppDimensions.p8),
              decoration: BoxDecoration(
                color: AppColors.lionGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                border: Border.all(color: AppColors.borderGreen),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.lionGreen, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Page updates automatically when ready.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.lionGreen),
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

/// Returns true when [error] is a Firestore 'failed-precondition' error,
/// which indicates an index is missing or still being built rather than a
/// permanent application error.
bool isChatIndexBuilding(Object error) {
  final msg = error.toString().toLowerCase();
  // Match only the specific Firestore composite-index error, not any error
  // that happens to contain the word "index".
  return msg.contains('failed-precondition') &&
      msg.contains('requires an index');
}
