import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/app_error_boundary.dart';
import 'package:chem_buddy/core/utils/safe_navigation.dart';

class _CrashingWidget extends StatelessWidget {
  const _CrashingWidget({required this.shouldCrash});
  final bool shouldCrash;

  @override
  Widget build(BuildContext context) {
    if (shouldCrash) {
      throw StateError('Simulated crash in test component');
    }
    return const Text('Normal Content Rendered Successfully');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('General Stability & Error Boundary Tests', () {
    testWidgets('1. AppErrorBoundary renders child when no exception occurs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorBoundary(
              screenName: 'Test Screen',
              child: _CrashingWidget(shouldCrash: false),
            ),
          ),
        ),
      );

      expect(find.text('Normal Content Rendered Successfully'), findsOneWidget);
    });

    testWidgets('2. AppErrorBoundary catches render error and displays friendly fallback card', (tester) async {
      final errorWidget = AppErrorBoundary.errorWidgetBuilder(
        FlutterErrorDetails(
          exception: StateError('Simulated rendering failure'),
          stack: StackTrace.current,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: errorWidget,
          ),
        ),
      );

      expect(find.text('Render Hiccup Encountered'), findsOneWidget);
      expect(find.textContaining('visual element could not be displayed'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });

    testWidgets('3. SafeNavigator wraps destination route in AppErrorBoundary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SafeNavigator.push(
                    context,
                    const Scaffold(body: Text('Protected Destination Screen')),
                    screenName: 'Protected Screen',
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Protected Destination Screen'), findsOneWidget);
      expect(find.byType(AppErrorBoundary), findsWidgets);
    });
  });
}
