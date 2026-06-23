import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isOwn;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isOwn ? 48 : 12,
          right: isOwn ? 12 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.displayName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.electricTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.type != ChatMessageType.chat) ...[
                      const SizedBox(width: 6),
                      _TypeBadge(type: message.type),
                    ],
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOwn ? AppColors.lionGreen : AppColors.bg2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwn ? 16 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOwn && message.type != ChatMessageType.chat)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _TypeBadge(type: message.type),
                    ),
                  Text(
                    message.text,
                    style: AppTextStyles.body.copyWith(
                      color: isOwn
                          ? AppColors.bg0
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ChatMessageType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isSong = type == ChatMessageType.songRequest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSong
            ? AppColors.electricTeal.withValues(alpha: 0.2)
            : AppColors.warningGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSong
              ? AppColors.electricTeal.withValues(alpha: 0.5)
              : AppColors.warningGold.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        isSong ? '🎵 SONG REQ' : '🎙 PITCH',
        style: AppTextStyles.caption.copyWith(
          color: isSong ? AppColors.electricTeal : AppColors.warningGold,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
