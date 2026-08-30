import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';
import 'package:chem_buddy/presentation/screens/review_timetable_screen.dart';

void main() {
  group('ReviewTimetableScreen Widget Tests', () {
    final sampleEntries = [
      const TimetableEntry(
        id: 'slot-1',
        dayOfWeek: 'Monday',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        subjectCode: 'CHE-501',
        subject: 'Advanced Organic Chemistry',
        teacherName: 'Dr. Sharma',
        room: 'Hall A',
        type: 'lecture',
      ),
      const TimetableEntry(
        id: 'slot-2',
        dayOfWeek: 'Wednesday',
        startTime: '02:00 PM',
        endTime: '04:00 PM',
        subjectCode: 'CHE-505',
        subject: 'Organic Synthesis Lab',
        teacherName: 'Dr. Patel',
        room: 'Lab 2',
        type: 'lab',
      ),
    ];

    testWidgets('1. Renders detected slots with day, subject, times, and types', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReviewTimetableScreen(
              initialEntries: sampleEntries,
              rawText: 'OCR Extracted Timetable Raw',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Timetable'), findsOneWidget);
      expect(find.text('2 Slots'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('09:00 AM'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.text('02:00 PM'), findsOneWidget);
      expect(find.text('04:00 PM'), findsOneWidget);
      expect(find.text('Confirm & Save Schedule →'), findsOneWidget);
    });

    testWidgets('2. Adds a new class slot when tapping + Add Class Slot', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReviewTimetableScreen(
              initialEntries: [sampleEntries.first],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsNothing);

      // Tap + Add Class Slot
      await tester.tap(find.text('+ Add Class Slot'));
      await tester.pumpAndSettle();

      expect(find.text('#2'), findsOneWidget);
      expect(find.text('2 Slots'), findsOneWidget);
    });

    testWidgets('3. Deletes a class slot when tapping delete icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReviewTimetableScreen(
              initialEntries: sampleEntries,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#2'), findsOneWidget);

      // Tap delete on second slot
      final deleteIcons = find.byIcon(Icons.delete_outline);
      expect(deleteIcons, findsNWidgets(2));
      await tester.tap(deleteIcons.at(1));
      await tester.pumpAndSettle();

      expect(find.text('#2'), findsNothing);
      expect(find.text('1 Slots'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });
  });
}
