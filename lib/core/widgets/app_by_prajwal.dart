import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppByPrajwal extends StatelessWidget {
  const AppByPrajwal({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Made by Prajwal A Kambar',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        fontSize: large ? 14 : 12,
        letterSpacing: 0.4,
      ),
    );
  }
}
