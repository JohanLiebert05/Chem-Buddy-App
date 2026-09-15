import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/presentation/screens/classes_hub_screen.dart';
import 'package:chem_buddy/presentation/screens/attendance_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    try {
      await HiveBoxes.openAll();
      await Hive.box(HiveBoxes.appTutorialState).put('completed', true);
    } catch (_) {}
  });

  group('Attendance Tracker Screen Layout & Overflow Tests', () {
    testWidgets('1. AttendanceScreen renders smoothly on standard mobile width (390px)', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. AttendanceScreen renders without overflow on compact mobile width (360px)', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 780 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. ClassesHubScreen switches to Attendance tab without crash or error card', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClassesHubScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Attendance tab
      final attendanceTab = find.text('Attendance');
      expect(attendanceTab, findsOneWidget);
      await tester.tap(attendanceTab);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Render Hiccup Encountered'), findsNothing);
      expect(find.text('Target Goal:'), findsOneWidget);
    });
  });
}
