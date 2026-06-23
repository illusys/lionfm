import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../requests/widgets/song_request_form.dart';

class ChatInactiveView extends StatefulWidget {
  final String? nextSessionNote;
  const ChatInactiveView({super.key, this.nextSessionNote});

  @override
  State<ChatInactiveView> createState() => _ChatInactiveViewState();
}

class _ChatInactiveViewState extends State<ChatInactiveView> {
  bool _showFallback = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Closed-state header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.p24),
          decoration: const BoxDecoration(
            color: AppColors.bg1,
            border: Border(
              bottom: BorderSide(color: AppColors.border1, width: 1),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.rFull),
                  border: Border.all(color: AppColors.border1),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textMuted,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppDimensions.p16),
              Text('Live Chat is Closed', style: AppTextStyles.h2),
              const SizedBox(height: AppDimensions.p8),
              Text(
                'Live chat opens during phone-in shows.\nTune in to join the conversation!',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (widget.nextSessionNote != null &&
                  widget.nextSessionNote!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.p12),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.p12),
                  decoration: BoxDecoration(
                    color: AppColors.lionGreen.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.r8),
                    border: Border.all(color: AppColors.borderGreen),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.lionGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.nextSessionNote!,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Fallback song request
        Expanded(
          child: _showFallback
              ? const SongRequestForm()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.p24),
                  child: Column(
                    children: [
                      Text(
                        'Can\'t wait? Send a song request now.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.p16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showFallback = true),
                          icon: const Icon(Icons.music_note_rounded,
                              size: 18),
                          label:
                              const Text('Submit a Song Request'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.borderGreen),
                            foregroundColor: AppColors.lionGreen,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
