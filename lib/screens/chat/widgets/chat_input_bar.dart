import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message_model.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ChatMessageType pendingType;
  final bool isSignedIn;
  final bool isBanned;
  final bool isSending;
  final VoidCallback onSongRequest;
  final VoidCallback onPitch;
  final VoidCallback onSend;
  final VoidCallback onSignInPrompt;
  final VoidCallback onClearType;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.pendingType,
    required this.isSignedIn,
    required this.isBanned,
    required this.isSending,
    required this.onSongRequest,
    required this.onPitch,
    required this.onSend,
    required this.onSignInPrompt,
    required this.onClearType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        border: Border(top: BorderSide(color: AppColors.border1, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick action row
          Padding(
            padding:
                const EdgeInsets.fromLTRB(AppDimensions.p12, AppDimensions.p8,
                    AppDimensions.p12, AppDimensions.p4),
            child: Row(
              children: [
                _QuickChip(
                  label: '🎵 Request a Song',
                  isActive: pendingType == ChatMessageType.songRequest,
                  color: AppColors.electricTeal,
                  onTap: onSongRequest,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: '🎙 Pitch a Show',
                  isActive: pendingType == ChatMessageType.pitch,
                  color: AppColors.warningGold,
                  onTap: onPitch,
                ),
                if (pendingType != ChatMessageType.chat) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onClearType,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          // Input row
          if (isBanned)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  border: Border.all(
                      color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'You are not able to post in chat.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.errorRed),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppTextStyles.body,
                      maxLength: 300,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: isSignedIn
                            ? 'Say something…'
                            : 'Sign in to chat',
                        hintStyle: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bg2,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.r20),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                      onTap: isSignedIn ? null : onSignInPrompt,
                      readOnly: !isSignedIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSending ? null : (isSignedIn ? onSend : onSignInPrompt),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenTealGradient,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.rFull),
                      ),
                      child: isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.bg0,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: AppColors.bg0, size: 18),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.7)
                : AppColors.border1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? color : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
