import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // PRIMARY BRAND
  static const Color lionGreen = Color(0xFF1E9B43);
  static const Color electricTeal = Color(0xFF28D7D2);
  static const Color midnightBlack = Color(0xFF0A0A0A);

  // SECONDARY
  static const Color lionGold = Color(0xFFC89A29);
  static const Color burntAmber = Color(0xFF8B5318);
  static const Color deepOrange = Color(0xFFE8650A);

  // NEUTRALS
  static const Color ivoryWhite = Color(0xFFF5F4EF);
  static const Color charcoal = Color(0xFF1C1C1C);

  // SURFACE LAYERS
  static const Color bg0 = Color(0xFF0A0A0A);
  static const Color bg1 = Color(0xFF111111);
  static const Color bg2 = Color(0xFF181818);
  static const Color bg3 = Color(0xFF222222);
  static const Color bg4 = Color(0xFF2C2C2C);

  // SEMANTIC
  static const Color liveRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF1E9B43);
  static const Color warningGold = Color(0xFFC89A29);
  static const Color errorRed = Color(0xFFDC2626);

  // TEXT
  static const Color textPrimary = Color(0xFFF5F4EF);
  static const Color textSecondary = Color(0xB3F5F4EF);
  static const Color textMuted = Color(0x66F5F4EF);
  static const Color textDisabled = Color(0x33F5F4EF);
  static const Color textTertiary = Color(0x66F5F4EF); // alias for textMuted

  // BORDERS
  static const Color border1 = Color(0x1AFFFFFF);
  static const Color border2 = Color(0x33FFFFFF);
  static const Color borderGold = Color(0x40C89A29);
  static const Color borderGreen = Color(0x401E9B43);
  static const Color borderTeal = Color(0x4028D7D2);

  // Keep legacy aliases used by existing code
  static const Color appBackground = bg0;
  static const Color surface1 = bg1;
  static const Color surface2 = bg2;
  static const Color surface3 = bg3;
  static const Color surface4 = bg4;
  static const Color amberGold = lionGold;
  static const Color electricBlue = electricTeal;
  static const Color unnDeepBlue = Color(0xFF003087);
  static const Color pureWhite = ivoryWhite;

  // Extra legacy aliases
  static const Color warningAmber = warningGold;
  static const Color emeraldGreen = lionGreen;
  static const Color unnGreen = lionGreen;
  static const Color border3 = border2;
  static const Color broadcastOrange = deepOrange;
  static const Color signalTeal = electricTeal;
  static const Color goldTint = Color(0xFF2A2008);
  static const Color blueTint = Color(0xFF08121A);
  static const Color greenTint = Color(0xFF081A0D);

  // GRADIENTS
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B14), Color(0xFF0A0A0A)],
  );

  static const LinearGradient greenTealGradient = LinearGradient(
    colors: [Color(0xFF1E9B43), Color(0xFF28D7D2)],
  );

  static const LinearGradient goldAmberGradient = LinearGradient(
    colors: [Color(0xFFC89A29), Color(0xFF8B5318)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC89A29), Color(0xFF8B5318)],
  );

  static const LinearGradient liveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B14), Color(0xFF0A1A12), Color(0xFF0A0A0A)],
  );

  static const RadialGradient greenGlow = RadialGradient(
    colors: [Color(0x331E9B43), Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient tealGlow = RadialGradient(
    colors: [Color(0x2228D7D2), Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient goldGlow = RadialGradient(
    colors: [Color(0x33C89A29), Colors.transparent],
    radius: 0.8,
  );
}
