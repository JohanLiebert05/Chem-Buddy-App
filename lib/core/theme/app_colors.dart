import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF07040F);
  static const backgroundAlt = Color(0xFF12091F);
  static const surface = Color(0xFF171022);
  static const surfaceElevated = Color(0xFF1F1630);
  static const card = Color(0xCC1A1328);
  static const border = Color(0x33C4B5FD);
  static const purple = Color(0xFF8B5CF6);
  static const purpleBright = Color(0xFFA78BFA);
  static const purpleDeep = Color(0xFF6D28D9);
  static const glow = Color(0x668B5CF6);
  static const textPrimary = Color(0xFFF5F3FF);
  static const textSecondary = Color(0xFFB8ADC9);
  static const textMuted = Color(0xFF7C728F);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const present = Color(0xFF34D399);
  static const absent = Color(0xFFF87171);
  static const postponed = Color(0xFF60A5FA);

  static const subjectPalette = [
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
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
