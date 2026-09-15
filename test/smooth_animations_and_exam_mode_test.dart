import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/core/utils/haptics.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/presentation/screens/exam_mode_screen.dart';
import 'package:chem_buddy/presentation/shell/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    SharedPreferences.setMockInitialValues({});
    try {
      await HiveBoxes.openAll();
      await Hive.box(HiveBoxes.appTutorialState).put('completed', true);
    } catch (_) {}
  });

  setUp(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('Failed to load font') ||
          details.exception.toString().contains('google_fonts')) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  group('Google Pixel Smart Haptics Tests', () {
    test('All AppHaptics methods complete safely without throwing', () async {
      await AppHaptics.selection();
      await AppHaptics.lightTap();
      await AppHaptics.tap();
      await AppHaptics.confirm();
      await AppHaptics.success();
      await AppHaptics.error();
      await AppHaptics.heavy();
      await AppHaptics.warn();
      await AppHaptics.warning();
      await AppHaptics.vibrate();
      expect(true, isTrue);
    });
  });

  group('Material 3 Theme & Page Transitions Tests', () {
    test('AppTheme has FadeForwardsPageTransitionsBuilder for Android', () {
      final builder = AppTheme.pageTransitionsTheme.builders[TargetPlatform.android];
      expect(builder, isA<FadeForwardsPageTransitionsBuilder>());
    });
  });

  group('MainShell Fluid Tab Switching & State Preservation Tests', () {
    testWidgets('Renders MainShell and switches between tabs seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'sans-serif'),
            home: const MainShell(),
          ),
        ),
      );
      await tester.pump();

      // Home tab is initially visible
      expect(find.text('Home'), findsWidgets);

      // Switch to Classes & Attendance
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // Switch to Ask AI
      await tester.tap(find.text('Ask AI'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // Switch to Library
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // Switch back to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Home'), findsWidgets);
    });
  });

  group('Exam Mode ChemistryMarkdownView Rendering Tests', () {
    testWidgets('Renders ExamModeScreen with ChemistryMarkdownView for questions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'sans-serif'),
            home: const Scaffold(
              body: ExamModeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final markdownViews = find.byType(ChemistryMarkdownView);
      expect(markdownViews, findsWidgets);
    });
  });
}
