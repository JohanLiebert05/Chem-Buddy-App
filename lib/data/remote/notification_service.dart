import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/attendance_math.dart';
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

  Future<void> sendTestNotification({SubjectAttendanceStats? stats}) async {
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
    
    final pctStr = stats != null && stats.counted > 0
        ? '${stats.percent.toStringAsFixed(1)}%'
        : '68.4%'; // Playful demo percentage if no logs yet

    await _plugin.show(
      99999,
      '🧪 ChemBuddy Alert Engine: Armed & Dangerous!',
      'Attendance tracker online ($pctStr in Organic Chem)! Expect witty banter, urgent attendance alerts, and zero excuses to bunk.',
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
    Map<String, SubjectAttendanceStats>? subjectStats,
    SubjectAttendanceStats? overallStats,
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
        // Resolve subject stats by code, name, or id
        final stats = subjectStats?[entry.subjectCode.trim().toUpperCase()] ??
            subjectStats?[entry.subject.trim().toUpperCase()] ??
            subjectStats?[entry.id];
        await _scheduleClass(entry, prefs.defaultMinutesBefore, stats: stats);
        scheduledCount++;
      }
    }
    if (prefs.dailyTimetable) {
      await _scheduleDaily(entries, overallStats: overallStats);
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

      final titles = [
        '🧠 Your brain cells are getting rusty!',
        '⚡ Active Recall Emergency: $setName',
        '🔬 Review time: $setName',
      ];
      final title = titles[setName.hashCode.abs() % titles.length];

      await _plugin.zonedSchedule(
        setId.hashCode,
        title,
        '${setCards.length} card(s) due! Memory decays exponentially without review—don\'t let your chemistry evaporate!',
        fire,
        const NotificationDetails(android: flashcardChannel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      count++;
    }
    return count;
  }

  /// Constructs cheeky, intelligent chemistry banter customized by subject attendance tier
  ({String title, String body}) _buildClassBanter({
    required String subjectName,
    required int minutesBefore,
    required String room,
    required String type,
    SubjectAttendanceStats? stats,
  }) {
    final locationInfo = room.trim().isNotEmpty ? ' in $room' : '';
    final timeStr = minutesBefore == 0 ? 'now' : 'in $minutesBefore min';

    if (stats == null || stats.counted == 0) {
      final banters = [
        'First impressions matter! Show up so the professor knows you actually exist this semester.',
        'Time to synthesize some attendance. Grab your notebook and head to class!',
        'Your attendance ledger is fresh. Start strong or suffer the consequences during finals!',
      ];
      final banter = banters[subjectName.hashCode.abs() % banters.length];
      return (
        title: '🧪 $subjectName starts $timeStr$locationInfo!',
        body: banter,
      );
    }

    final pct = stats.percent;
    final pctStr = '${pct.toStringAsFixed(1)}%';

    if (pct < 70.0) {
      // Critical danger tier (< 70%)
      final needed = stats.attendToReach75;
      final banters = [
        'Sitting at $pctStr attendance? That is dangerously close to a hall ticket hostage situation. Drag yourself to class!',
        'Your attendance is a tragic $pctStr. The professor thinks you are a mythical creature. Show up today!',
        'You are at $pctStr (Need $needed consecutive classes for 75%). Stop calculating minimum probabilities and attend!',
        'Only $pctStr attendance?! If you bunk today, your HOD will personally haunt you. Move those legs!',
      ];
      final banter = banters[subjectName.hashCode.abs() % banters.length];
      return (
        title: '🚨 $subjectName ($pctStr) in $timeStr$locationInfo!',
        body: banter,
      );
    } else if (pct < 75.0) {
      // Borderline warning tier (70% - 74.9%)
      final banters = [
        'You are sitting on the razor\'s edge at $pctStr. ONE missed class and you lose eligibility. Run to class!',
        'Attendance: $pctStr. The attendance gods are watching you closely. Don\'t even think about sleeping in!',
        '$pctStr in $subjectName! You are walking on thin ice. Get into class and secure that percentage.',
      ];
      final banter = banters[subjectName.hashCode.abs() % banters.length];
      return (
        title: '⚠️ $subjectName ($pctStr) in $timeStr$locationInfo!',
        body: banter,
      );
    } else if (pct < 85.0) {
      // Safe tier (75% - 84.9%)
      final skips = stats.canSkip;
      final banters = [
        '$pctStr attendance—you passed the 75% cutoff, but don\'t get cocky. Class starts $timeStr!',
        'You are at $pctStr. You have $skips safe bunk(s), but save them for a real emergency. Be a good chemist today!',
        '$subjectName ($pctStr). Protect that buffer like an air-sensitive Grignard reagent!',
      ];
      final banter = banters[subjectName.hashCode.abs() % banters.length];
      return (
        title: '⏳ $subjectName ($pctStr) starts $timeStr$locationInfo',
        body: banter,
      );
    } else {
      // Exemplary tier (85%+)
      final banters = [
        '$pctStr attendance?! Look at you, academic weapon! Don\'t let that flawless streak slip now.',
        'Flexing a stellar $pctStr in $subjectName! The professor might actually know your name. See you in class!',
        '$pctStr attendance! High yield, zero impurities. Keep up the chemistry mastery!',
      ];
      final banter = banters[subjectName.hashCode.abs() % banters.length];
      return (
        title: '🌟 $subjectName ($pctStr) in $timeStr$locationInfo',
        body: banter,
      );
    }
  }

  Future<void> _scheduleClass(
    TimetableEntry entry,
    int minutesBefore, {
    SubjectAttendanceStats? stats,
  }) async {
    final start = entry.startMinutes;
    var hour = start ~/ 60;
    var minute = start % 60 - minutesBefore;
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    if (hour < 0) return;
    final next = _nextWeekday(entry.weekdayNumber, hour, minute);
    final title = entry.displayName.isEmpty ? 'Chemistry Class' : entry.displayName;

    final banter = _buildClassBanter(
      subjectName: title,
      minutesBefore: minutesBefore,
      room: entry.room,
      type: entry.type,
      stats: stats,
    );

    await _plugin.zonedSchedule(
      entry.id.hashCode,
      banter.title,
      banter.body,
      next,
      const NotificationDetails(android: classChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _scheduleDaily(
    List<TimetableEntry> entries, {
    SubjectAttendanceStats? overallStats,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var fire = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 30);
    if (fire.isBefore(now)) fire = fire.add(const Duration(days: 1));
    final weekday = fire.weekday;
    final today = entries.where((e) => e.weekdayNumber == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    String title;
    String body;

    if (today.isEmpty) {
      title = '☕ Zero classes today! Rest day.';
      body = overallStats != null && overallStats.counted > 0
          ? 'Overall attendance sitting at ${overallStats.percent.toStringAsFixed(1)}%. Recharge those synapses!'
          : 'No classes on schedule. Sleep in or catch up on chemistry research!';
    } else {
      final count = today.length;
      final classList = today.map((e) => '• ${e.startTime} ${e.displayName}').join('\n');

      if (overallStats != null && overallStats.counted > 0) {
        final pct = overallStats.percent;
        final pctStr = '${pct.toStringAsFixed(1)}%';
        if (pct < 75.0) {
          title = '🚨 Wake up! $count class(es) today · Overall: $pctStr';
          body = 'Your overall attendance is in the danger zone ($pctStr). No bunking allowed today!\n$classList';
        } else {
          title = '🌅 Rise & Shine! $count class(es) today · Overall: $pctStr';
          body = 'Overall attendance is solid at $pctStr. Let\'s keep the momentum going!\n$classList';
        }
      } else {
        title = '🌅 Rise & Shine! $count class(es) today';
        body = 'Your bed is comfortable, but passing your semester is better. Today\'s lineup:\n$classList';
      }
    }

    await _plugin.zonedSchedule(
      71001,
      title,
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
