import 'package:flutter/material.dart';

/// ChemBuddy Design System v4.0 — Material 3 Expressive Tokens
///
/// Semantic color roles inspired by Material 3 tonal surfaces.
/// Dark-first, chemistry-themed, Pixel-quality.
class AppColors {
  AppColors._();

  // ─── Core Canvas & Surface Tones ───────────────────────────────────
  /// Deepest background — scaffold, app canvas
  static const bg0 = Color(0xFF0A0914);

  /// Standard surface — cards, containers, sheets
  static const bg1 = Color(0xFF131127);

  /// Elevated surface — raised cards, inputs, chips
  static const bg2 = Color(0xFF1E1B38);

  /// Highest surface — modals, dialogs, popovers
  static const bg3 = Color(0xFF252240);

  // ─── Surface Container Tones (M3 Expressive) ──────────────────────
  static const surfaceContainerLowest = Color(0xFF0C0B18);
  static const surfaceContainerLow = Color(0xFF11101F);
  static const surfaceContainer = Color(0xFF161429);
  static const surfaceContainerHigh = Color(0xFF1C1A33);
  static const surfaceContainerHighest = Color(0xFF23213C);

  // ─── Border Hierarchy ──────────────────────────────────────────────
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderMedium = Color(0x24FFFFFF);
  static const borderHighlight = Color(0x47A78BFA);
  static const borderAccent = Color(0x808B5CF6);

  // ─── Brand Colors ──────────────────────────────────────────────────
  static const brandPrimary = Color(0xFF8B5CF6);
  static const electricViolet = Color(0xFF8B5CF6);
  static const brandBright = Color(0xFFA78BFA);
  static const brandDeep = Color(0xFF6B45FA);

  // ─── Accent Colors (Semantic Chemistry Categories) ─────────────────
  static const accentCyan = Color(0xFF06B6D4);
  static const accentGold = Color(0xFFF59E0B);
  static const accentPink = Color(0xFFF472B6);
  static const accentBlue = Color(0xFF60A5FA);

  // ─── Status Colors ─────────────────────────────────────────────────
  static const statusSuccess = Color(0xFF10B981);
  static const statusWarning = Color(0xFFF59E0B);
  static const statusDanger = Color(0xFFEF4444);
  static const statusInfo = Color(0xFF60A5FA);

  // ─── Text Hierarchy ────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB8BCC8);
  static const textMuted = Color(0xFF8B909D);
  static const textDisabled = Color(0xFF555866);

  // ─── Semantic Aliases (Legacy Compat — used across 150+ files) ─────
  static const background = bg0;
  static const backgroundAlt = bg1;
  static const surface = bg1;
  static const surfaceElevated = bg2;
  static const card = Color(0xE0131127);
  static const border = borderSubtle;
  static const purple = brandBright;
  static const purpleBright = brandBright;
  static const purpleDeep = brandDeep;
  static const blue = accentBlue;
  static const glow = Color(0x66A78BFA);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const present = Color(0xFF34D399);
  static const absent = Color(0xFFF87171);
  static const postponed = Color(0xFF60A5FA);
  static const excused = Color(0xFF38BDF8);

  // ─── Brand Gradients (Used sparingly) ──────────────────────────────
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGlowGradient = RadialGradient(
    colors: [Color(0x338B5CF6), Colors.transparent],
    radius: 0.8,
  );

  // ─── Subject Palette ───────────────────────────────────────────────
  static const subjectPalette = [
    Color(0xFFA78BFA),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
  ];

  /// Returns a semantic color for attendance percentage thresholds.
  static Color attendanceColor(double percent) {
    if (percent >= 75) return success;
    if (percent >= 65) return warning;
    return danger;
  }
}
