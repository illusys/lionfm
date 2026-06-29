// Flutter SDK target: 3.24.5 (stable)
// Do not use API introduced after Flutter 3.24.5.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../models/station.dart';

class AppTheme {
  AppTheme._();

  /// Lion FM default — hard-coded Midnight Gold palette.
  static ThemeData get dark => _buildTheme(
        primary: AppColors.lionGold,
        onPrimary: AppColors.bg0,
        primaryContainer: AppColors.darkGold,
        secondary: AppColors.pepperRed,
        accentBorder: AppColors.borderGold,
        focusBorder: AppColors.borderGold,
      );

  /// Neutral FMStream default — teal/navy, used while a tenant station
  /// is loading or when no station branding is available.
  static ThemeData get fmstreamDefault => _buildTheme(
        primary: const Color(0xFF15E0B4), // FMStream teal
        onPrimary: const Color(0xFF0B1639), // FMStream navy
        primaryContainer: const Color(0xFF0B2050),
        secondary: const Color(0xFF0B1639),
        accentBorder: const Color(0x6015E0B4),
        focusBorder: const Color(0x6015E0B4),
      );

  /// Per-tenant theme built from a station's brand colors.
  /// Falls back gracefully: any color not in the brand palette keeps
  /// the Lion FM default so the FMStream dark surface system is preserved.
  static ThemeData fromBrandColors(StationBrandColors colors) {
    final primary = colors.primaryColor;
    final secondary = colors.secondaryColor;
    // Compute readable text on primary based on luminance
    final onPrimary = primary.computeLuminance() > 0.4 ? AppColors.bg0 : Colors.white;
    // Derive a container color: blend primary into the darkest surface
    final primaryContainer = Color.alphaBlend(primary.withValues(alpha: 0.25), AppColors.bg0);
    final accentBorder = primary.withValues(alpha: 0.6);
    final focusBorder = primary.withValues(alpha: 0.6);

    return _buildTheme(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      secondary: secondary,
      accentBorder: accentBorder,
      focusBorder: focusBorder,
    );
  }

  static ThemeData _buildTheme({
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color secondary,
    required Color accentBorder,
    required Color focusBorder,
  }) {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: const Color(0xFFFFDEA0),
      secondary: secondary,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.deepRed,
      onSecondaryContainer: const Color(0xFFFFCCB5),
      tertiary: AppColors.onAirGreen,
      onTertiary: const Color(0xFF003828),
      tertiaryContainer: const Color(0xFF00523A),
      onTertiaryContainer: const Color(0xFF70EFC5),
      surface: AppColors.bg2,
      onSurface: AppColors.textPrimary,
      surfaceContainerLow: AppColors.bg1,
      surfaceContainerHigh: AppColors.bg3,
      error: AppColors.errorRed,
      onError: AppColors.textPrimary,
      outline: AppColors.warmBorder,
      outlineVariant: AppColors.border2,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg0,
      primaryColor: primary,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg1,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        shape: Border(
          bottom: BorderSide(color: accentBorder, width: 1),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg1,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 10),
      ),

      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r16),
          side: BorderSide(color: accentBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.r12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border2),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.r12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r10),
          borderSide: const BorderSide(color: AppColors.border1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r10),
          borderSide: const BorderSide(color: AppColors.border1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r10),
          borderSide: BorderSide(color: focusBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r10),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r10),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bg3,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r12)),
        behavior: SnackBarBehavior.floating,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg3,
        side: const BorderSide(color: AppColors.border2),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.rFull)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border1,
        thickness: 0.5,
        space: 0,
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: AppColors.bg3,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.16),
      ),
    );
  }
}
