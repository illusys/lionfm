import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heroTitle => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 11,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.inter(
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

  static TextStyle get liveLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: AppColors.liveRed,
        letterSpacing: 1.0,
      );

  static TextStyle get badgeText => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 9,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get tagline => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        height: 1.5,
      );

  static TextStyle get navLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 10,
        height: 1.2,
      );

  static TextStyle get categoryLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 9,
        color: AppColors.amberGold,
        letterSpacing: 0.8,
      );
}
