import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF111318);
  static const backgroundAlt = Color(0xFF1A1C22);
  static const surface = Color(0xFF1A1C22);
  static const surfaceElevated = Color(0xFF22242C);
  static const card = Color(0xE01A1C22);
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
