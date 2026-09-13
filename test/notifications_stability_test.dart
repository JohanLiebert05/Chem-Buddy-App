import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/library_models.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
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
    await HiveBoxes.openAll();
  });

  tearDownAll(() async {
    await Hive.close();
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

    test('2. Resync schedules timetable classes, daily summary, events, and due flashcard reviews', () async {
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

      final sampleEvents = [
        AcademicEvent(
          id: 'event-1',
          title: 'Organometallics Midterm',
          type: EventType.test,
          dueDate: DateTime.now().add(const Duration(days: 3)),
          completed: false,
        ),
      ];

      final sampleReminders = [
        AppReminder(
          id: 'rem-1',
          title: 'Review Stereochemistry Notes',
          when: DateTime.now().add(const Duration(hours: 5)),
          kind: 'revision',
        ),
      ];

      final sampleSets = [
        SmartFlashcardSet(
          id: 'deck-1',
          title: 'Pericyclic Reactions Deck',
          sourceFileName: 'pericyclic.pdf',
          topic: 'Pericyclic',
          cardCount: 5,
          createdAt: DateTime.now(),
        ),
      ];

      final sampleCards = [
        SmartFlashcard(
          id: 'card-1',
          setId: 'deck-1',
          question: 'What is Woodward-Hoffmann rule?',
          answer: 'Conservation of orbital symmetry',
          position: 0,
          nextReviewAt: DateTime.now().add(const Duration(hours: 12)),
        ),
      ];

      await service.resync(
        prefs: const NotificationPrefs(
          enabled: true,
          classReminders: true,
          dailyTimetable: true,
          assignmentReminders: true,
          examReminders: true,
          studyReminders: true,
          defaultMinutesBefore: 15,
        ),
        entries: sampleEntries,
        events: sampleEvents,
        reminders: sampleReminders,
        flashcardSets: sampleSets,
        smartCards: sampleCards,
      );

      expect(service.ready, isTrue);

      final scheduled = methodCalls.where((c) => c.method == 'zonedSchedule').toList();
      expect(scheduled.length, greaterThan(0));

      // Test with notifications disabled clears all
      methodCalls.clear();
      await service.resync(
        prefs: const NotificationPrefs(enabled: false),
        entries: sampleEntries,
        events: sampleEvents,
        reminders: sampleReminders,
      );
      final cancelAll = methodCalls.where((c) => c.method == 'cancelAll').toList();
      expect(cancelAll.length, greaterThan(0));
    });

    test('3. Immediate test notification dispatches to Android notification manager', () async {
      final service = NotificationService.instance;
      await service.init();
      methodCalls.clear();

      await service.sendTestNotification();
      final shown = methodCalls.where((c) => c.method == 'show').toList();
      expect(shown.length, equals(1));
      expect(shown.first.arguments['title'], contains('ChemBuddy Test Notification'));
    });

    testWidgets('4. NotificationSettingsScreen displays test notification button and flashcard reminder toggle', (tester) async {
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
      expect(find.text('Flashcard & study reminders'), findsOneWidget);

      final buttonFinder = find.textContaining('Send Test Notification');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Test notification dispatched'), findsOneWidget);
    });
  });
}
