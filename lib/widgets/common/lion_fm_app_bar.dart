import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

class LionFmAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extra;
  final PreferredSizeWidget? bottom;

  const LionFmAppBar({
    super.key,
    required this.title,
    this.extra,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg0,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderGreen, width: 0.5),
      ),
      titleSpacing: 16,
      title: Text(title, style: AppTextStyles.h3),
      actions: [
        ...?extra,
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Image.asset(
            'assets/images/lionfm_logo.png',
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
      ],
      bottom: bottom,
    );
  }
}
