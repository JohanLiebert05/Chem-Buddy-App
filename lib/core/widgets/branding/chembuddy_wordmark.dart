import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// The official ChemBuddy Wordmark with graduate subtitle badge.
class ChemBuddyWordmark extends StatelessWidget {
  const ChemBuddyWordmark({
    super.key,
    this.fontSize = 24,
    this.showTag = true,
    this.tagText = 'MSc Chemistry',
    this.alignment = CrossAxisAlignment.center,
  });

  final double fontSize;
  final bool showTag;
  final String tagText;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFA78BFA), // Purple light
              Color(0xFF8B5CF6), // Purple bright
              Color(0xFF06B6D4), // Cyan
            ],
            stops: [0.0, 0.45, 1.0],
          ).createShader(bounds),
          child: Text(
            'ChemBuddy',
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        if (showTag) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.25),
                  AppColors.blue.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.purpleBright.withValues(alpha: 0.35),
                width: 0.7,
              ),
            ),
            child: Text(
              tagText.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: fontSize * 0.34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.accentCyan,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
