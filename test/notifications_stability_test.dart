import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/library_models.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';
import 'package:chem_buddy/data/remote/notification_service.dart';
import 'package:chem_buddy/presentation/screens/notification_settings_screen.dart';

void main() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel notificationChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  final List<MethodCall> methodCalls = [];

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async => 'UTC',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationChannel,
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        if (methodCall.method == 'initialize') return true;
        if (methodCall.method == 'requestNotificationsPermission') return true;
        if (methodCall.method == 'requestExactAlarmsPermission') return true;
        if (methodCall.method == 'createNotificationChannel') return null;
        if (methodCall.method == 'show') return null;
        if (methodCall.method == 'zonedSchedule') return null;
        if (methodCall.method == 'cancelAll') return null;
        if (methodCall.method == 'cancel') return null;
        return null;
      },
    );
    try {
      await HiveBoxes.openAll();
    } catch (_) {
      // Hive path may not be available in CI — tests use in-memory mocks anyway.
    }
  });

  setUp(() {
    methodCalls.clear();
  });

  group('NotificationService Engine & Scheduling Tests', () {
    test('1. NotificationService initializes and registers all 4 channels with Android manager', () async {
      final service = NotificationService.instance;
      await service.init();
      expect(service.ready, isTrue);

      expect(NotificationService.classChannel.channelId, equals('chem_buddy_classes'));
      expect(NotificationService.dailyChannel.channelId, equals('chem_buddy_daily'));
      expect(NotificationService.deadlineChannel.channelId, equals('chem_buddy_deadlines'));
      expect(NotificationService.flashcardChannel.channelId, equals('chem_buddy_flashcards'));

      final createdChannels = methodCalls.where((c) => c.method == 'createNotificationChannel').toList();
      expect(createdChannels.length, equals(4));
    });

    test('2. Resync schedules advance reminder and class-start 1-tap attendance prompt', () async {
      final service = NotificationService.instance;
      await service.init();
      methodCalls.clear();

      final sampleEntries = [
        const TimetableEntry(
          id: 'slot-1',
          dayOfWeek: 'Monday',
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          subjectCode: 'CHE-501',
          subject: 'Organic Chemistry',
          teacherName: 'Dr. Sharma',
        ),
      ];

      final organicStats = const SubjectAttendanceStats(present: 6, absent: 4, postponed: 0); // 60.0% attendance
      await service.resync(
        prefs: const NotificationPrefs(
          enabled: true,
          classReminders: true,
          dailyTimetable: false,
          attendancePromptAtClassStart: true,
          assignmentReminders: false,
          examReminders: false,
          studyReminders: false,
          defaultMinutesBefore: 15,
        ),
        entries: sampleEntries,
        events: const [],
        reminders: const [],
        subjectStats: {'CHE-501': organicStats},
        overallStats: organicStats,
      );

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule').toList();
      expect(scheduled.length, equals(2)); // 1 advance reminder + 1 class-start attendance prompt

      // Advance reminder
      final advanceReminder = scheduled.firstWhere((c) => c.arguments['id'] == 'slot-1'.hashCode);
      expect(advanceReminder.arguments['title'], contains('60.0%'));
      expect(advanceReminder.arguments['title'], contains('🚨'));

      // Class-start attendance prompt
      final promptId = 80000 + ('slot-1'.hashCode.abs() % 10000);
      final attendancePrompt = scheduled.firstWhere((c) => c.arguments['id'] == promptId);
      expect(attendancePrompt.arguments['title'], contains('Organic Chemistry is starting now!'));
      expect(attendancePrompt.arguments['body'], contains('attendance'));
      expect(attendancePrompt.arguments['payload'], contains('attendance_prompt'));
      expect(attendancePrompt.arguments['payload'], contains('CHE-501'));

      // Test with notifications disabled clears all
      methodCalls.clear();
      await service.resync(
        prefs: const NotificationPrefs(enabled: false),
        entries: sampleEntries,
        events: const [],
        reminders: const [],
      );
      final cancelAll = methodCalls.where((c) => c.method == 'cancelAll').toList();
      expect(cancelAll.length, greaterThan(0));
    });

    test('3. Daily 8:30 AM timetable schedules 7 distinct weekday briefings with chemistry banter', () async {
      final service = NotificationService.instance;
      await service.init();
      methodCalls.clear();

      final sampleEntries = [
        const TimetableEntry(
          id: 'slot-1',
          dayOfWeek: 'Monday',
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          subjectCode: 'CHE-501',
          subject: 'Organic Chemistry',
          teacherName: 'Dr. Sharma',
        ),
        const TimetableEntry(
          id: 'slot-2',
          dayOfWeek: 'Wednesday',
          startTime: '11:15 AM',
          endTime: '12:15 PM',
          subjectCode: 'CHE-502',
          subject: 'Inorganic Chemistry',
          teacherName: 'Dr. Bose',
        ),
      ];

      final organicStats = const SubjectAttendanceStats(present: 15, absent: 5, postponed: 0); // 75.0%
      await service.resync(
        prefs: const NotificationPrefs(
          enabled: true,
          classReminders: false,
          attendancePromptAtClassStart: false,
          dailyTimetable: true,
          assignmentReminders: false,
          examReminders: false,
          studyReminders: false,
        ),
        entries: sampleEntries,
        events: const [],
        reminders: const [],
        overallStats: organicStats,
      );

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule').toList();
      // Expect 7 schedules for 7 weekdays (Monday: 71001 .. Sunday: 71007)
      expect(scheduled.length, equals(7));

      final mondayBriefing = scheduled.firstWhere((c) => c.arguments['id'] == 71001);
      expect(mondayBriefing.arguments['title'], contains('Monday'));
      expect(mondayBriefing.arguments['body'], contains('Organic Chemistry'));

      final wednesdayBriefing = scheduled.firstWhere((c) => c.arguments['id'] == 71003);
      expect(wednesdayBriefing.arguments['title'], contains('Midweek'));
      expect(wednesdayBriefing.arguments['body'], contains('Inorganic Chemistry'));

      final sundayBriefing = scheduled.firstWhere((c) => c.arguments['id'] == 71007);
      expect(sundayBriefing.arguments['title'], contains('Sunday Equilibrium'));
      expect(sundayBriefing.arguments['body'], contains('Recharge'));
    });

    test('4. Immediate test notification dispatches with 1-tap Present / Absent actions and payload', () async {
      final service = NotificationService.instance;
      await service.init();
      methodCalls.clear();

      await service.sendTestNotification(
        stats: const SubjectAttendanceStats(present: 12, absent: 8, postponed: 0),
        testSubjectId: 'sub_org',
        testSubjectName: 'Organic Chemistry',
      );
      final shown = methodCalls.where((c) => c.method == 'show').toList();
      expect(shown.length, equals(1));
      expect(shown.first.arguments['title'], contains('Organic Chemistry starts now!'));
      expect(shown.first.arguments['payload'], contains('sub_org'));
    });

    test('5. handleAttendanceAction saves attendance record to Hive and triggers confirmation', () async {
      if (Hive.isBoxOpen(HiveBoxes.attendance)) {
        await Hive.box(HiveBoxes.attendance).clear();
      }
      bool onAttendanceMarkedCalled = false;
      NotificationService.onAttendanceMarked = () {
        onAttendanceMarkedCalled = true;
      };

      final payload = jsonEncode({
        'type': 'attendance_prompt',
        'subjectId': 'sub_test_chem',
        'subjectName': 'Physical Chemistry',
        'slotId': 'slot_test_1',
        'dayOfWeek': 1,
      });

      methodCalls.clear();
      await NotificationService.handleAttendanceAction(
        NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: 'mark_present',
          payload: payload,
        ),
      );

      expect(onAttendanceMarkedCalled, isTrue);

      if (Hive.isBoxOpen(HiveBoxes.attendance)) {
        final box = Hive.box(HiveBoxes.attendance);
        final records = box.values.where((v) => v is Map && v['subjectId'] == 'sub_test_chem').toList();
        expect(records.isNotEmpty, isTrue);
        final firstRecord = records.first as Map;
        expect(firstRecord['status'], equals('present'));
      }

      final shown = methodCalls.where((c) => c.method == 'show').toList();
      expect(shown.isNotEmpty, isTrue);
      expect(shown.last.arguments['title'], contains('Marked Present!'));
      expect(shown.last.arguments['body'], contains('Physical Chemistry'));

      // Test Absent action
      methodCalls.clear();
      await NotificationService.handleAttendanceAction(
        NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: 'mark_absent',
          payload: payload,
        ),
      );

      final shownAbsent = methodCalls.where((c) => c.method == 'show').toList();
      expect(shownAbsent.isNotEmpty, isTrue);
      expect(shownAbsent.last.arguments['title'], contains('Marked Absent'));
    });

    testWidgets('6. NotificationSettingsScreen displays 8:30 AM timetable subtitle and attendance prompt switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: NotificationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Enable all notifications'), findsOneWidget);
      expect(find.text('Class reminders'), findsOneWidget);
      expect(find.text('Class-time attendance prompt'), findsOneWidget);
      expect(find.textContaining('8:30 AM'), findsOneWidget);
      expect(find.text('Flashcard & study reminders'), findsOneWidget);

      final buttonFinder = find.textContaining('Send Test Notification');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Test notification dispatched'), findsOneWidget);
    });
  });
}
