import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/library_models.dart';
import '../models/models.dart';
import '../models/smart_flashcard.dart';
import '../models/timetable_entry.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;

  static const classChannel = AndroidNotificationDetails(
    'chem_buddy_classes',
    'Class reminders',
    channelDescription: 'Upcoming lecture and lab reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const dailyChannel = AndroidNotificationDetails(
    'chem_buddy_daily',
    'Daily timetable',
    channelDescription: 'Morning overview of today’s classes',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const deadlineChannel = AndroidNotificationDetails(
    'chem_buddy_deadlines',
    'Tests & assignments',
    channelDescription: 'Reminders for upcoming chemistry deadlines',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const flashcardChannel = AndroidNotificationDetails(
    'chem_buddy_flashcards',
    'Study & Flashcards',
    channelDescription: 'Spaced repetition flashcard review reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tzdata.initializeTimeZones();
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: DarwinInitializationSettings()),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Explicitly register Android 8.0+ notification channels
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'chem_buddy_classes',
        'Class reminders',
        description: 'Upcoming lecture and lab reminders',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'chem_buddy_daily',
        'Daily timetable',
        description: 'Morning overview of today’s classes',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'chem_buddy_deadlines',
        'Tests & assignments',
        description: 'Reminders for upcoming chemistry deadlines',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'chem_buddy_flashcards',
        'Study & Flashcards',
        description: 'Spaced repetition flashcard review reminders',
        importance: Importance.high,
      ));

      await androidPlugin.requestNotificationsPermission();
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('[NotificationService] Exact alarm permission request: $e');
      }
    }
    ready = true;
    debugPrint('[NotificationService] Initialized with 4 channels and permissions');
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    return granted;
  }

  Future<void> sendTestNotification() async {
    if (!ready) await init();
    debugPrint('[NotificationService] Triggering test notification');
    const androidDetails = AndroidNotificationDetails(
      'chem_buddy_classes',
      'Class reminders',
      channelDescription: 'Upcoming lecture and lab reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(
      99999,
      '🧪 ChemBuddy Test Notification',
      'Notifications are functioning! Class, timetable, and study reminders are active.',
      details,
    );
  }

  Future<void> resync({
    required NotificationPrefs prefs,
    required List<TimetableEntry> entries,
    required List<AcademicEvent> events,
    required List<AppReminder> reminders,
    List<SmartFlashcardSet>? flashcardSets,
    List<SmartFlashcard>? smartCards,
  }) async {
    if (!ready) await init();
    await _plugin.cancelAll();
    if (!prefs.enabled) {
      debugPrint('[NotificationService] Notifications disabled in preferences; cleared all alarms');
      return;
    }

    int scheduledCount = 0;

    if (prefs.classReminders) {
      for (final entry in entries) {
        await _scheduleClass(entry, prefs.defaultMinutesBefore);
        scheduledCount++;
      }
    }
    if (prefs.dailyTimetable) {
      await _scheduleDaily(entries);
      scheduledCount++;
    }
    if (prefs.assignmentReminders || prefs.examReminders) {
      for (final event in events.where((e) => !e.completed)) {
        final isExam = event.type == EventType.test;
        if (isExam && !prefs.examReminders) continue;
        if (!isExam && !prefs.assignmentReminders) continue;
        await scheduleEvent(event);
        scheduledCount++;
      }
    }
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
      scheduledCount++;
    }

    if (prefs.studyReminders && smartCards != null && smartCards.isNotEmpty) {
      final scheduledSets = await _scheduleFlashcardReviews(smartCards, flashcardSets ?? const []);
      scheduledCount += scheduledSets;
    }

    debugPrint('[NotificationService] Resync complete. Scheduled $scheduledCount active notifications/alarms.');
  }

  Future<int> _scheduleFlashcardReviews(List<SmartFlashcard> cards, List<SmartFlashcardSet> sets) async {
    final now = DateTime.now();
    final upcomingCards = cards.where((c) => c.nextReviewAt != null && c.nextReviewAt!.isAfter(now)).toList();
    if (upcomingCards.isEmpty) return 0;

    final Map<String, List<SmartFlashcard>> grouped = {};
    for (final card in upcomingCards) {
      grouped.putIfAbsent(card.setId, () => []).add(card);
    }

    int count = 0;
    for (final entry in grouped.entries) {
      final setId = entry.key;
      final setCards = entry.value;
      setCards.sort((a, b) => a.nextReviewAt!.compareTo(b.nextReviewAt!));
      final earliest = setCards.first.nextReviewAt!;
      final setName = sets.where((s) => s.id == setId).firstOrNull?.title ?? 'Chemistry Deck';

      final fire = tz.TZDateTime.from(earliest, tz.local);
      if (fire.isBefore(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        setId.hashCode,
        '📚 Flashcards Due: $setName',
        '${setCards.length} chemistry card(s) ready for active recall review.',
        fire,
        const NotificationDetails(android: flashcardChannel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      count++;
    }
    return count;
  }

  Future<void> _scheduleClass(TimetableEntry entry, int minutesBefore) async {
    final start = entry.startMinutes;
    var hour = start ~/ 60;
    var minute = start % 60 - minutesBefore;
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    if (hour < 0) return;
    final next = _nextWeekday(entry.weekdayNumber, hour, minute);
    final title = entry.displayName.isEmpty ? 'Class' : entry.displayName;
    await _plugin.zonedSchedule(
      entry.id.hashCode,
      '$title starts in $minutesBefore minutes',
      '${entry.type} · ${entry.startTime}${entry.room.isEmpty ? '' : ' · ${entry.room}'}',
      next,
      const NotificationDetails(android: classChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _scheduleDaily(List<TimetableEntry> entries) async {
    final now = tz.TZDateTime.now(tz.local);
    var fire = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 30);
    if (fire.isBefore(now)) fire = fire.add(const Duration(days: 1));
    final weekday = fire.weekday;
    final today = entries.where((e) => e.weekdayNumber == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final body = today.isEmpty
        ? 'No classes scheduled today.'
        : today.map((e) => '${e.startTime} ${e.displayName}').join('\n');
    await _plugin.zonedSchedule(
      71001,
      'Good morning! Here is your timetable for today.',
      body,
      fire,
      const NotificationDetails(android: dailyChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (candidate.weekday != weekday || candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
      candidate = tz.TZDateTime(tz.local, candidate.year, candidate.month, candidate.day, hour, minute);
    }
    return candidate;
  }

  Future<void> scheduleEvent(AcademicEvent event) async {
    if (!ready || event.completed) return;
    final when = tz.TZDateTime.from(event.dueDate, tz.local).subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);
    var fire = when.isBefore(now)
        ? tz.TZDateTime.from(event.dueDate, tz.local).subtract(const Duration(hours: 2))
        : when.add(const Duration(hours: 9));
    if (fire.isBefore(now)) return;
    await _plugin.zonedSchedule(
      event.id.hashCode,
      '${event.type.name.toUpperCase()}: ${event.title}',
      'Due ${event.dueDate.year}-${event.dueDate.month.toString().padLeft(2, '0')}-${event.dueDate.day.toString().padLeft(2, '0')}',
      fire,
      const NotificationDetails(android: deadlineChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleReminder(AppReminder reminder) async {
    if (!ready) return;
    final fire = tz.TZDateTime.from(reminder.when, tz.local);
    if (fire.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.kind.toUpperCase(),
      fire,
      const NotificationDetails(android: deadlineChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(String id) => _plugin.cancel(id.hashCode);
}
