import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // PRIMARY BRAND — Midnight Gold system
  static const Color lionGold = Color(0xFFF5A623);     // primary accent
  static const Color darkGold = Color(0xFF7A4A00);     // primary container
  static const Color lionGreen = Color(0xFF1E9B43);    // kept for legacy / semantic success
  static const Color electricTeal = Color(0xFF28D7D2); // kept for legacy / semantic info
  static const Color midnightBlack = Color(0xFF0A0A0A);

  // SECONDARY / TERTIARY
  static const Color pepperRed = Color(0xFFFF5733);    // secondary accent
  static const Color deepRed = Color(0xFF7A1A00);      // secondary container
  static const Color onAirGreen = Color(0xFF4CAF8A);   // tertiary — on-air indicator

  // LEGACY secondary palette
  static const Color burntAmber = Color(0xFF8B5318);
  static const Color deepOrange = Color(0xFFE8650A);

  // NEUTRALS
  static const Color ivoryWhite = Color(0xFFF5E6D3);   // warm ivory
  static const Color charcoal = Color(0xFF1C1C1C);

  // SURFACE LAYERS — warm dark (Deep Ember system)
  static const Color bg0 = Color(0xFF0F0803);  // Deep Ember — scaffold background
  static const Color bg1 = Color(0xFF1E120A);  // Burnished  — app bar / bottom nav
  static const Color bg2 = Color(0xFF2E1A0B);  // Lifted Amber — cards
  static const Color bg3 = Color(0xFF3D2310);  // Modal Floor — chips / modals
  static const Color bg4 = Color(0xFF4A2E18);  // Raised — highest elevation

  // SEMANTIC
  static const Color liveRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF1E9B43);
  static const Color warningGold = Color(0xFFC89A29);
  static const Color errorRed = Color(0xFFDC2626);

  // TEXT — warm ivory scale
  static const Color textPrimary = Color(0xFFF5E6D3);
  static const Color textSecondary = Color(0xB3F5E6D3);
  static const Color textMuted = Color(0x66F5E6D3);
  static const Color textDisabled = Color(0x33F5E6D3);
  static const Color textTertiary = Color(0x66F5E6D3);

  // BORDERS — warm ivory / gold tinted
  static const Color border1 = Color(0x1AF5E6D3);     // subtle divider
  static const Color border2 = Color(0x33F5E6D3);     // visible divider
  static const Color borderGold = Color(0x60F5A623);  // gold accent border
  static const Color borderGreen = Color(0x401E9B43); // legacy green border
  static const Color borderTeal = Color(0x4028D7D2);  // legacy teal border
  static const Color warmBorder = Color(0xFF6B4A2A);  // solid amber border

  // GRADIENTS
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF59E0B), Color(0xFF92400E)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E1A0B), Color(0xFF0F0803)],
  );

  static const LinearGradient goldAmberGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFF8B5318)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFF8B5318)],
  );

  static const LinearGradient greenTealGradient = LinearGradient(
    colors: [Color(0xFF1E9B43), Color(0xFF28D7D2)],
  );

  static const LinearGradient liveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E1A0B), Color(0xFF1E120A), Color(0xFF0F0803)],
  );

  static const RadialGradient goldGlow = RadialGradient(
    colors: [Color(0x33F5A623), Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient greenGlow = RadialGradient(
    colors: [Color(0x331E9B43), Colors.transparent],
    radius: 0.8,
  );

  static const RadialGradient tealGlow = RadialGradient(
    colors: [Color(0x2228D7D2), Colors.transparent],
    radius: 0.8,
  );

  // LEGACY ALIASES — keep so existing screens compile unchanged
  static const Color appBackground = bg0;
  static const Color surface1 = bg1;
  static const Color surface2 = bg2;
  static const Color surface3 = bg3;
  static const Color surface4 = bg4;
  static const Color amberGold = lionGold;
  static const Color electricBlue = electricTeal;
  static const Color unnDeepBlue = Color(0xFF003087);
  static const Color pureWhite = ivoryWhite;
  static const Color warningAmber = warningGold;
  static const Color emeraldGreen = lionGreen;
  static const Color unnGreen = lionGreen;
  static const Color border3 = border2;
  static const Color broadcastOrange = deepOrange;
  static const Color signalTeal = electricTeal;
  static const Color goldTint = Color(0xFF2E1A0B);    // matches bg2
  static const Color blueTint = Color(0xFF08121A);
  static const Color greenTint = Color(0xFF081A0D);
}
