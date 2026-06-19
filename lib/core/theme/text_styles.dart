import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _spaceGrotesk = 'SpaceGrotesk';
  static const String _inter = 'Inter';

  static const TextStyle heroTitle = TextStyle(
    fontFamily: _spaceGrotesk,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _spaceGrotesk,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _spaceGrotesk,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _spaceGrotesk,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    color: AppColors.textTertiary,
    height: 1.4,
    letterSpacing: 0.8,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static const TextStyle liveLabel = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    color: AppColors.liveRed,
    letterSpacing: 1.0,
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 9,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
    height: 1.5,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    height: 1.2,
  );

  static const TextStyle categoryLabel = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 9,
    color: AppColors.amberGold,
    letterSpacing: 0.8,
  );
}
