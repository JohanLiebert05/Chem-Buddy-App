import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/presentation/providers/app_providers.dart';
import 'package:chem_buddy/presentation/shell/main_shell.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await HiveBoxes.openAll();
    await Hive.box(HiveBoxes.appTutorialState).put('completed', true);
  });

  tearDownAll(() async {
    await Hive.close();
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

  void assertNoAppCrash(WidgetTester tester, {String? context}) {
    final ex = tester.takeException();
    if (ex != null) {
      final str = ex.toString();
      if (str.contains('Failed to load font') || str.contains('google_fonts')) {
        return;
      }
      fail('Unexpected crash${context != null ? ' ($context)' : ''}: $ex');
    }
  }

  group('Bottom Navigation Bar Stability & Rapid Switch Tests', () {
    testWidgets('1. Rapidly switches tabs 30+ times in a row without crashing or throwing duplicate key errors', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(IndexedStack), findsOneWidget);

      // Perform 30 rapid switches across all tabs in random and sequential orders
      const switchSequence = [
        1, 2, 3, 4, 0,
        2, 0, 1, 3, 2,
        4, 1, 0, 3, 4,
        2, 1, 0, 4, 3,
        1, 0, 2, 4, 1,
        3, 0, 2, 1, 4,
      ];

      for (final tabIndex in switchSequence) {
        container.read(shellTabProvider.notifier).state = tabIndex;
        // Pump minimal frame to simulate high-frequency user interactions
        await tester.pump(const Duration(milliseconds: 16));
        assertNoAppCrash(tester, context: 'rapidly switching to tab $tabIndex');
      }

      await tester.pump(const Duration(milliseconds: 100));

      // Verify MainShell and IndexedStack are healthy and rendered
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(4)); // Last tab in sequence
      expect(indexedStack.children.length, equals(5));
    });

    testWidgets('2. Handles out-of-bounds tab index gracefully via clamping', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Negative out-of-bounds index
      container.read(shellTabProvider.notifier).state = -5;
      await tester.pump(const Duration(milliseconds: 100));
      assertNoAppCrash(tester, context: 'negative index');

      var indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(0)); // Clamped to 0

      // 2. High out-of-bounds index
      container.read(shellTabProvider.notifier).state = 999;
      await tester.pump(const Duration(milliseconds: 100));
      assertNoAppCrash(tester, context: 'high index');

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(4)); // Clamped to 4

      // 3. Return to valid
      container.read(shellTabProvider.notifier).state = 2;
      await tester.pump(const Duration(milliseconds: 100));
      assertNoAppCrash(tester, context: 'return to valid index 2');

      indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, equals(2));
    });
  });
}
