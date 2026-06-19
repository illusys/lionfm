import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── PRIMARY ──────────────────────────────────────────────
  static const Color unnDeepBlue = Color(0xFF003087);
  static const Color lionGold = Color(0xFFB8860B);
  static const Color unnGreen = Color(0xFF1B5E20);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ── SECONDARY ────────────────────────────────────────────
  static const Color electricBlue = Color(0xFF004DB3);
  static const Color amberGold = Color(0xFFE6A800);
  static const Color emeraldGreen = Color(0xFF2E7D32);
  static const Color broadcastOrange = Color(0xFFFF6B00);
  static const Color signalTeal = Color(0xFF00BCD4);

  // ── SURFACES ─────────────────────────────────────────────
  static const Color appBackground = Color(0xFF0A0F1E);
  static const Color surface1 = Color(0xFF0F1629);
  static const Color surface2 = Color(0xFF141D35);
  static const Color surface3 = Color(0xFF1A2340);
  static const Color surface4 = Color(0xFF202B4A);

  // ── TINTS ────────────────────────────────────────────────
  static const Color blueTint = Color(0xFFD6E4F0);
  static const Color goldTint = Color(0xFFFDF3D0);
  static const Color greenTint = Color(0xFFE8F5E9);

  // ── SEMANTIC ─────────────────────────────────────────────
  static const Color liveRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);

  // ── TEXT ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textTertiary = Color(0x59FFFFFF);
  static const Color textMuted = Color(0x40FFFFFF);

  // ── BORDERS ──────────────────────────────────────────────
  static const Color border1 = Color(0x14FFFFFF);
  static const Color border2 = Color(0x24FFFFFF);
  static const Color border3 = Color(0x40FFFFFF);

  // ── GRADIENTS ────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF001245), Color(0xFF0A0F1E)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE6A800), Color(0xFFB8860B)],
  );

  static const RadialGradient goldGlow = RadialGradient(
    colors: [Color(0x33E6A800), Colors.transparent],
    radius: 0.8,
  );
}
