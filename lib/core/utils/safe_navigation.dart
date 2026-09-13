import 'package:flutter/material.dart';
import '../widgets/app_error_boundary.dart';

/// Navigation helper that wraps pushed destination screens in an [AppErrorBoundary]
/// and guards against navigation exceptions, ensuring an isolated screen failure
/// never crashes the host screen or application.
class SafeNavigator {
  SafeNavigator._();

  /// Pushes a new route with automatic error boundary protection.
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget screen, {
    String? screenName,
  }) async {
    try {
      return await Navigator.of(context).push<T>(
        MaterialPageRoute<T>(
          builder: (_) => AppErrorBoundary(
            screenName: screenName,
            child: screen,
          ),
          settings: RouteSettings(name: screenName),
        ),
      );
    } catch (e, stack) {
      debugPrint('[SafeNavigator] Error pushing route $screenName: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${screenName ?? "page"}. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Pushes a replacement route with automatic error boundary protection.
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen, {
    String? screenName,
    TO? result,
  }) async {
    try {
      return await Navigator.of(context).pushReplacement<T, TO>(
        MaterialPageRoute<T>(
          builder: (_) => AppErrorBoundary(
            screenName: screenName,
            child: screen,
          ),
          settings: RouteSettings(name: screenName),
        ),
        result: result,
      );
    } catch (e, stack) {
      debugPrint('[SafeNavigator] Error replacing route $screenName: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not navigate to ${screenName ?? "page"}. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }
}
