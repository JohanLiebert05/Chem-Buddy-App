import 'package:flutter/material.dart';

class AppColors {
  // --- Authoritative Design System v3.0 Tokens ---
  static const bg0 = Color(0xFF0A0914); // Deepest canvas background
  static const bg1 = Color(0xFF131127); // Standard card & container surface
  static const bg2 = Color(0xFF1E1B38); // Elevated surfaces, chips, inputs

  static const borderSubtle = Color(0x14FFFFFF); // Hairline borders
  static const borderHighlight = Color(0x47A78BFA); // Selected/focused states
  static const borderAccent = Color(0x808B5CF6); // Interactive card highlights

  static const brandPrimary = Color(0xFF8B5CF6); // Vibrant brand purple
  static const brandBright = Color(0xFFA78BFA); // Lavender heading/LaTeX
  static const brandDeep = Color(0xFF6B45FA); // Royal glow violet
  static const accentCyan = Color(0xFF06B6D4); // Spectroscopy / lab cyan
  static const accentGold = Color(0xFFF59E0B); // Streaks / mastery gold

  static const statusSuccess = Color(0xFF10B981);
  static const statusWarning = Color(0xFFF59E0B);
  static const statusDanger = Color(0xFFEF4444);
  static const statusInfo = Color(0xFF60A5FA);

  static const brandGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGlowGradient = RadialGradient(
    colors: [Color(0x338B5CF6), Colors.transparent],
    radius: 0.8,
  );

  // --- Legacy Compatibility Aliases (Preserve 100% existing code) ---
  static const background = Color(0xFF0A0914);
  static const backgroundAlt = Color(0xFF131127);
  static const surface = Color(0xFF131127);
  static const surfaceElevated = Color(0xFF1E1B38);
  static const card = Color(0xE0131127);
  static const border = Color(0x14FFFFFF);
  static const purple = Color(0xFFA78BFA);
  static const purpleBright = Color(0xFFA78BFA);
  static const purpleDeep = Color(0xFF6B45FA);
  static const blue = Color(0xFF60A5FA);
  static const glow = Color(0x66A78BFA);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB8BCC8);
  static const textMuted = Color(0xFF8B909D);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const present = Color(0xFF34D399);
  static const absent = Color(0xFFF87171);
  static const postponed = Color(0xFF60A5FA);
  static const excused = Color(0xFF38BDF8);

  static const subjectPalette = [
    Color(0xFFA78BFA),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
  ];

  static Color attendanceColor(double percent) {
    if (percent >= 75) return success;
    if (percent >= 65) return warning;
    return danger;
  }
}
