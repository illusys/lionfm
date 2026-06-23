import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/chat_message_model.dart';

class PinnedMessageBar extends StatelessWidget {
  final ChatMessageModel message;

  const PinnedMessageBar({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lionGreen.withValues(alpha: 0.12),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderGreen, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin_rounded,
              color: AppColors.lionGreen, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.lionGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  message.text,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
