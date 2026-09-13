import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/widgets/app_error_boundary.dart';
import 'data/local/local_store.dart';
import 'data/remote/notification_service.dart';
import 'data/remote/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Intercept Flutter framework render and layout errors with in-theme error card
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] Caught framework error: ${details.exceptionAsString()}');
  };

  // 2. Custom ErrorWidget to replace red/grey crash screen with ChemBuddy fallback card
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorBoundary.errorWidgetBuilder(details);
  };

  // 3. Catch unhandled asynchronous Dart exceptions across isolates and futures
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformDispatcher] Unhandled async exception: $error\n$stack');
    // Return true to indicate the error has been handled and avoid terminating the app
    return true;
  };

  try {
    await HiveBoxes.openAll();
  } catch (e) {
    debugPrint('[Main] Error opening Hive boxes: $e');
  }

  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('[Main] Error initializing Supabase: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[Main] Error initializing Notifications: $e');
  }

  runApp(const ProviderScope(child: ChemBuddyApp()));
}
