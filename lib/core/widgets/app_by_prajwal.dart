import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppByPrajwal extends StatelessWidget {
  const AppByPrajwal({super.key, this.large = false, this.showVersion = true});

  final bool large;
  final bool showVersion;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVersion)
          Text(
            'ChemBuddy v2.8.2',
            style: TextStyle(
              color: AppColors.purpleBright,
              fontWeight: FontWeight.w800,
              fontSize: large ? 13 : 11,
              letterSpacing: 0.8,
            ),
          ),
        if (showVersion) const SizedBox(height: 2),
        Text(
          'Developed by Prajwal A Kambar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: large ? 13 : 11.5,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
