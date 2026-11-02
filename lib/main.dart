import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/providers/appearance_provider.dart';
import 'core/widgets/app_error_boundary.dart';
import 'data/local/local_store.dart';
import 'data/remote/notification_service.dart';
import 'data/remote/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Intercept Flutter framework render and layout errors with in-theme error card
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(
      '[FlutterError] Caught framework error: ${details.exceptionAsString()}',
    );
  };

  // 2. Custom ErrorWidget to replace red/grey crash screen with ChemBuddy fallback card
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorBoundary.errorWidgetBuilder(details);
  };

  // 3. Catch unhandled asynchronous Dart exceptions across isolates and futures
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint(
      '[PlatformDispatcher] Unhandled async exception: $error\n$stack',
    );
    // Return true to indicate the error has been handled and avoid terminating the app
    return true;
  };

  runApp(const ChemBuddyBootstrap());
}

Future<Widget> initializeChemBuddy() async {
  // Start independent I/O together, after the first branded Flutter frame.
  final storage = HiveBoxes.openAll();
  final preferences = SharedPreferences.getInstance().then<SharedPreferences?>(
    (value) => value,
    onError: (Object error) {
      debugPrint('[Appearance] Preferences unavailable: $error');
      return null;
    },
  );
  final cloud = _initializeCloud();
  await storage;
  // Notification callbacks access Hive; initialize only after boxes are ready.
  await Future.wait([cloud, _initializeNotifications()]);
  final appearanceStorage = await preferences;
  return ProviderScope(
    overrides: [appearanceStorageProvider.overrideWithValue(appearanceStorage)],
    child: const ChemBuddyApp(),
  );
}

// A local-storage retry must not initialize the Supabase singleton twice.
Future<void>? _cloudInitialization;
Future<void> _initializeCloud() => _cloudInitialization ??= _setupCloud();

Future<void> _setupCloud() async {
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('[Main] Error initializing Supabase: $e');
  }
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[Main] Error initializing Notifications: $e');
  }
}

/// Draw immediately instead of holding the native window during service setup.
class ChemBuddyBootstrap extends StatefulWidget {
  const ChemBuddyBootstrap({super.key, this.initialize = initializeChemBuddy});
  final Future<Widget> Function() initialize;

  @override
  State<ChemBuddyBootstrap> createState() => _ChemBuddyBootstrapState();
}

class _ChemBuddyBootstrapState extends State<ChemBuddyBootstrap> {
  Widget? _ready;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() => _failed = false);
    try {
      final ready = await widget.initialize();
      if (mounted) setState(() => _ready = ready);
    } catch (error, stack) {
      debugPrint('[Startup] Local storage unavailable: $error\n$stack');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready != null) return _ready!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF7028E4)),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F2FA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.science_rounded,
                  size: 64,
                  color: Color(0xFF7028E4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ChemBuddy',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('by Prajwal A Kambar'),
                const SizedBox(height: 28),
                if (_failed) ...[
                  const Text('Unable to open your saved data.'),
                  TextButton(onPressed: _start, child: const Text('Try again')),
                ] else
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
