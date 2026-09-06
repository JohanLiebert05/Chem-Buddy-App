import 'package:flutter/services.dart';

/// Light tactile feedback for Chem Buddy interactions.
class AppHaptics {
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> lightTap() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> tap() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> confirm() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> warn() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }
}

