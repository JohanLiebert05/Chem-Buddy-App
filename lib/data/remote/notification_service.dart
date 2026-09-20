import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../core/utils/attendance_math.dart';
import '../local/local_store.dart';
import '../models/library_models.dart';
import '../models/models.dart';
import '../models/smart_flashcard.dart';
import '../models/timetable_entry.dart';
import '../services/psychology_facts_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  NotificationService.handleAttendanceAction(details);
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static VoidCallback? onAttendanceMarked;

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

  static const psychologyFactChannel = AndroidNotificationDetails(
    'chem_buddy_psychology_facts',
    'Daily Psychology Facts',
    channelDescription: 'Fascinating daily insights into human behavior, memory, and cognitive psychology',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      // Force IST (Asia/Kolkata) if timezone detection fails or returns empty
      final tzName = name.isNotEmpty ? name : 'Asia/Kolkata';
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tzdata.initializeTimeZones();
      // Fallback: Force IST timezone for Indian students
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {}
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'attendance_actions',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'mark_present',
              'Present ✅',
            ),
            DarwinNotificationAction.plain(
              'mark_absent',
              'Absent ❌',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: NotificationService.handleAttendanceAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'chem_buddy_psychology_facts',
        'Daily Psychology Facts',
        description: 'Fascinating daily insights into human behavior, memory, and cognitive psychology',
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
    debugPrint('[NotificationService] Initialized with 5 channels and permissions');
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    return granted;
  }

  static Future<void> handleAttendanceAction(NotificationResponse details) async {
    final action = details.actionId;
    if (action != 'mark_present' && action != 'mark_absent') return;
    final payload = details.payload;
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final subjectId = data['subjectId'] as String?;
    final subjectName = data['subjectName'] as String? ?? 'Class';
    final slotId = data['slotId'] as String?;
    if (subjectId == null || subjectId.isEmpty) return;

    final status = action == 'mark_present' ? AttendanceStatus.present : AttendanceStatus.absent;

    try {
      await HiveBoxes.openAll();
    } catch (_) {}

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final box = Hive.box(HiveBoxes.attendance);
    String? existingId;
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final d = raw['date'] as String?;
        final sId = raw['subjectId'] as String?;
        final slot = raw['slotId'] as String?;
        if (sId == subjectId && slot == slotId && (d?.startsWith(todayStr) ?? false)) {
          existingId = key.toString();
          break;
        }
      }
    }

    final recordId = existingId ?? const Uuid().v4();
    final record = AttendanceRecord(
      id: recordId,
      subjectId: subjectId,
      date: today,
      status: status,
      slotId: slotId,
      markedAt: now,
      note: 'Marked via notification (${status == AttendanceStatus.present ? "Present" : "Absent"})',
    );

    await box.put(recordId, record.toJson());

    try {
      onAttendanceMarked?.call();
    } catch (e) {
      debugPrint('[NotificationService] onAttendanceMarked error: $e');
    }

    // Instant confirmation feedback notification
    final isPresent = status == AttendanceStatus.present;
    final confirmTitle = isPresent ? '✅ Marked Present!' : '❌ Marked Absent';
    final confirmBody = isPresent
        ? 'Attendance logged for $subjectName. Keep up the high yield!'
        : 'Logged absent for $subjectName. Don\'t let the percentage drop!';

    try {
      await instance._plugin.show(
        99000 + (slotId?.hashCode.abs() ?? subjectId.hashCode.abs()) % 1000,
        confirmTitle,
        confirmBody,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chem_buddy_classes',
            'Class reminders',
            channelDescription: 'Upcoming lecture and lab reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing confirmation: $e');
    }
  }

  Future<void> sendTestNotification({
    SubjectAttendanceStats? stats,
    String? testSubjectId,
    String? testSubjectName,
  }) async {
    if (!ready) await init();
    debugPrint('[NotificationService] Triggering test notification');
    const androidDetails = AndroidNotificationDetails(
      'chem_buddy_classes',
      'Class reminders',
      channelDescription: 'Upcoming lecture and lab reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_present',
          'Present ✅',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'mark_absent',
          'Absent ❌',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(categoryIdentifier: 'attendance_actions'),
    );

    final pctStr = stats != null && stats.counted > 0
        ? '${stats.percent.toStringAsFixed(1)}%'
        : '68.4%'; // Playful demo percentage if no logs yet

    final subId = testSubjectId ?? 'test_organic_chem';
    final subName = testSubjectName ?? 'Organic Chemistry';

    final payload = jsonEncode({
      'type': 'attendance_prompt',
      'subjectId': subId,
      'subjectName': subName,
      'slotId': 'test_slot_0',
      'dayOfWeek': DateTime.now().weekday,
    });

    await _plugin.show(
      99999,
      '🧪 $subName starts now! ($pctStr)',
      'ChemBuddy Action Shade: Tap "Present ✅" or "Absent ❌" below to log attendance instantly without opening the app!',
      details,
      payload: payload,
    );
  }

  Future<void> sendTestPsychologyFactNotification({PsychologyFact? fact}) async {
    if (!ready) await init();
    final pFact = fact ?? PsychologyFactsService.instance.getTodayFact();
    final title = '${pFact.emoji} Psychology Fact: ${pFact.title}';
    final body = '${pFact.fact}\n\n💡 Insight: ${pFact.takeaway}';

    final payload = jsonEncode({
      'type': 'psychology_fact',
      'factId': pFact.id,
      'title': pFact.title,
      'category': pFact.category,
    });

    await _plugin.show(
      99888,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chem_buddy_psychology_facts',
          'Daily Psychology Facts',
          channelDescription: 'Fascinating daily insights into human behavior, memory, and cognitive psychology',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> resync({
    required NotificationPrefs prefs,
    required List<TimetableEntry> entries,
    required List<AcademicEvent> events,
    required List<AppReminder> reminders,
    List<Subject>? subjects,
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

    if (prefs.classReminders || prefs.attendancePromptAtClassStart) {
      for (final entry in entries) {
        // Resolve subject stats by code, name, or id
        final stats = subjectStats?[entry.subjectCode.trim().toUpperCase()] ??
            subjectStats?[entry.subject.trim().toUpperCase()] ??
            subjectStats?[entry.id];

        final matchedSubject = subjects?.where((s) {
          final codeMatch = s.code.trim().isNotEmpty &&
              s.code.trim().toUpperCase() == entry.subjectCode.trim().toUpperCase();
          final nameMatch = s.name.trim().isNotEmpty &&
              s.name.trim().toUpperCase() == entry.subject.trim().toUpperCase();
          final idMatch = s.id == entry.subjectCode || s.id == entry.id;
          return codeMatch || nameMatch || idMatch;
        }).firstOrNull;

        final resolvedSubjectId = matchedSubject?.id ?? entry.subjectCode;

        await _scheduleClass(
          entry,
          prefs.defaultMinutesBefore,
          stats: stats,
          subjectId: resolvedSubjectId,
          scheduleReminder: prefs.classReminders,
          scheduleAttendancePrompt: prefs.attendancePromptAtClassStart,
        );
        scheduledCount++;
      }
    }
    if (prefs.dailyTimetable) {
      await _scheduleDaily(entries, overallStats: overallStats);
      scheduledCount += 7;
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

    if (prefs.dailyPsychologyFact) {
      final scheduledFacts = await _scheduleDailyPsychologyFacts(prefs);
      scheduledCount += scheduledFacts;
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
    String? subjectId,
    bool scheduleReminder = true,
    bool scheduleAttendancePrompt = true,
  }) async {
    final title = entry.displayName.isEmpty ? 'Chemistry Class' : entry.displayName;

    // 1. Advance reminder before class — NOW with 1-tap attendance actions
    if (scheduleReminder) {
      final start = entry.startMinutes;
      var reminderHour = start ~/ 60;
      var reminderMinute = start % 60 - minutesBefore;
      // Fix midnight underflow: roll back to previous day if needed
      while (reminderMinute < 0) {
        reminderMinute += 60;
        reminderHour -= 1;
      }
      var reminderWeekday = entry.weekdayNumber;
      while (reminderHour < 0) {
        reminderHour += 24;
        reminderWeekday -= 1;
        if (reminderWeekday < 1) reminderWeekday = 7;
      }
      final next = _nextWeekday(reminderWeekday, reminderHour, reminderMinute);
      final banter = _buildClassBanter(
        subjectName: title,
        minutesBefore: minutesBefore,
        room: entry.room,
        type: entry.type,
        stats: stats,
      );

      // Advance reminder payload for 1-tap attendance marking
      final advancePayload = jsonEncode({
        'type': 'attendance_prompt',
        'subjectId': subjectId ?? entry.subjectCode,
        'subjectName': title,
        'slotId': entry.id,
        'dayOfWeek': entry.weekdayNumber,
      });

      const androidAdvanceReminder = AndroidNotificationDetails(
        'chem_buddy_classes',
        'Class reminders',
        channelDescription: 'Upcoming lecture and lab reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'mark_present',
            'Present ✅',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'mark_absent',
            'Absent ❌',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      const iosAdvanceReminder = DarwinNotificationDetails(
        categoryIdentifier: 'attendance_actions',
      );

      await _plugin.zonedSchedule(
        entry.id.hashCode.abs(),
        banter.title,
        banter.body,
        next,
        const NotificationDetails(android: androidAdvanceReminder, iOS: iosAdvanceReminder),
        payload: advancePayload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    // 2. Class-time attendance prompt (at exact class start) with direct 1-tap Present / Absent actions
    if (scheduleAttendancePrompt) {
      final startHour = entry.startMinutes ~/ 60;
      final startMinute = entry.startMinutes % 60;
      final classStart = _nextWeekday(entry.weekdayNumber, startHour, startMinute);

      final pct = stats != null && stats.counted > 0 ? ' (${stats.percent.toStringAsFixed(1)}%)' : '';
      final quips = [
        'Are you seated in class$pct or planning a stealth bunk? Tap to mark attendance:',
        'Class is starting! Tap Present ✅ or Absent ❌ right here—no excuses:',
        'Equilibrium shift time! Are you in lecture$pct? Tap to log:',
        'Synthesizing attendance points! Tap Present ✅ or Absent ❌:',
      ];
      final promptBody = quips[entry.displayName.hashCode.abs() % quips.length];

      final payload = jsonEncode({
        'type': 'attendance_prompt',
        'subjectId': subjectId ?? entry.subjectCode,
        'subjectName': title,
        'slotId': entry.id,
        'dayOfWeek': entry.weekdayNumber,
      });

      const androidAttendance = AndroidNotificationDetails(
        'chem_buddy_classes',
        'Class reminders',
        channelDescription: 'Upcoming lecture and lab reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'mark_present',
            'Present ✅',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'mark_absent',
            'Absent ❌',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      const iosAttendance = DarwinNotificationDetails(
        categoryIdentifier: 'attendance_actions',
      );

      await _plugin.zonedSchedule(
        80000 + (entry.id.hashCode.abs() % 10000),
        '🧪 $title is starting now!',
        promptBody,
        classStart,
        const NotificationDetails(android: androidAttendance, iOS: iosAttendance),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Day';
    }
  }

  static ({String title, String body}) _buildDailyBriefing({
    required int weekday,
    required String dayName,
    required List<TimetableEntry> entries,
    String? overallPctStr,
  }) {
    if (entries.isEmpty) {
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        return (
          title: '☕ $dayName Equilibrium · No classes today!',
          body: overallPctStr != null
              ? 'Overall attendance: $overallPctStr. Lab is dark and reagents are resting. Recharge your synapses!'
              : 'Lab is quiet and beakers are resting. Recharge your synapses for the week ahead!',
        );
      }
      return (
        title: '🎉 Free Day ($dayName) · Zero classes scheduled',
        body: overallPctStr != null
            ? 'Overall attendance sitting at $overallPctStr. Sleep in or catch up on chemistry research!'
            : 'Zero lectures on the books today. Sleep in or dive into your chemistry projects!',
      );
    }

    final count = entries.length;
    final scheduleLines = entries
        .map((e) => '• ${e.startTime} ${e.displayName}${e.room.trim().isNotEmpty ? " (${e.room.trim()})" : ""}')
        .join('\n');

    final pctInfo = overallPctStr != null ? ' · $overallPctStr' : '';

    if (overallPctStr != null) {
      final pctNum = double.tryParse(overallPctStr.replaceAll('%', '').trim()) ?? 100.0;
      if (pctNum < 75.0) {
        return (
          title: '🚨 $dayName Alert: $count class(es) today · $overallPctStr',
          body: 'Attendance danger zone! Zero bunks permitted today. Class timetable:\n$scheduleLines',
        );
      } else if (pctNum >= 85.0) {
        return (
          title: '🌟 $dayName Briefing: $count class(es) today$pctInfo',
          body: 'High yield academic weapon! Let\'s keep that streak alive:\n$scheduleLines',
        );
      }
    }

    switch (weekday) {
      case DateTime.monday:
        return (
          title: '⚗️ Monday Kickoff: $count class(es) today$pctInfo',
          body: 'Synthesize that morning momentum! Activation energy is high, but passing is better:\n$scheduleLines',
        );
      case DateTime.wednesday:
        return (
          title: '⚡ Midweek Reaction: $count class(es) today$pctInfo',
          body: 'Transition state reached! Keep driving the equilibrium forward:\n$scheduleLines',
        );
      case DateTime.friday:
        return (
          title: '🎉 Friday Sprint: $count class(es) today$pctInfo',
          body: 'Final reaction cycle before the weekend! Knock these out:\n$scheduleLines',
        );
      default:
        return (
          title: '🌅 $dayName Briefing: $count class(es) today$pctInfo',
          body: 'Your bed has high entropy, but lectures build stability. Today\'s lineup:\n$scheduleLines',
        );
    }
  }

  Future<void> _scheduleDaily(
    List<TimetableEntry> entries, {
    SubjectAttendanceStats? overallStats,
  }) async {
    final pctStr = overallStats != null && overallStats.counted > 0
        ? '${overallStats.percent.toStringAsFixed(1)}%'
        : null;

    for (int weekday = 1; weekday <= 7; weekday++) {
      final next = _nextWeekday(weekday, 8, 30);
      final dayEntries = entries.where((e) => e.weekdayNumber == weekday).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

      final dayName = _weekdayName(weekday);
      final briefing = _buildDailyBriefing(
        weekday: weekday,
        dayName: dayName,
        entries: dayEntries,
        overallPctStr: pctStr,
      );

      await _plugin.zonedSchedule(
        71000 + weekday,
        briefing.title,
        briefing.body,
        next,
        const NotificationDetails(android: dailyChannel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<int> _scheduleDailyPsychologyFacts(NotificationPrefs prefs) async {
    final now = tz.TZDateTime.now(tz.local);
    final hour = prefs.psychologyFactHour;
    final minute = prefs.psychologyFactMinute;
    int scheduled = 0;

    // Schedule for the next 30 days so each day gets a distinct, non-repeating psychology fact
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day + dayOffset, hour, minute);
      if (candidate.isBefore(now)) {
        continue;
      }

      final date = DateTime(candidate.year, candidate.month, candidate.day);
      final fact = PsychologyFactsService.instance.getFactForDay(date);

      final title = '${fact.emoji} Psychology Fact: ${fact.title}';
      final body = '${fact.fact}\n\n💡 Insight: ${fact.takeaway}';

      final payload = jsonEncode({
        'type': 'psychology_fact',
        'factId': fact.id,
        'title': fact.title,
        'category': fact.category,
      });

      await _plugin.zonedSchedule(
        65000 + dayOffset,
        title,
        body,
        candidate,
        const NotificationDetails(
          android: psychologyFactChannel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      scheduled++;
    }
    return scheduled;
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

    final dueStr =
        '${event.dueDate.day}/${event.dueDate.month}/${event.dueDate.year}';
    final String body;
    if (event.type == EventType.test) {
      final quips = [
        'Exam due $dueStr! Review those mechanisms — electron arrows wait for no one. ⚡',
        'Test on $dueStr. Your Gibbs energy of anxiety is rising. Channel it into revision! 🧠',
        'Tomorrow\'s exam is today\'s panic if you don\'t study NOW. Due $dueStr. 📚',
        'The exam doesn\'t care about Le Chatelier\'s principle — pressure only increases. Due $dueStr. ⚗️',
      ];
      body = quips[event.title.hashCode.abs() % quips.length];
    } else if (event.type == EventType.assignment) {
      final quips = [
        'Assignment due $dueStr. Like a reaction without a catalyst, it won\'t complete itself. ⏳',
        'Submit by $dueStr or face the irreversible reaction of a late penalty. 😬',
        'Your assignment has a half-life of $dueStr — act before it decays! ☢️',
      ];
      body = quips[event.title.hashCode.abs() % quips.length];
    } else {
      body = 'Coming up on $dueStr. Don\'t let this slip through like a volatile solvent! 💨';
    }

    await _plugin.zonedSchedule(
      event.id.hashCode,
      '${event.type.name.toUpperCase()}: ${event.title}',
      body,
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
      _friendlyReminderBody(reminder),
      fire,
      const NotificationDetails(android: deadlineChannel, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Converts a reminder's kind into a witty, human-friendly notification body.
  String _friendlyReminderBody(AppReminder reminder) {
    final kind = reminder.kind.toLowerCase().trim();
    final title = reminder.title.trim();
    if (kind.contains('exam') || kind.contains('test') || kind.contains('viva')) {
      final quips = [
        'Your neurons won\'t fire themselves. Time to crack open those notes! ⚗️',
        'The periodic table isn\'t going to memorise itself. Get studying! 🧪',
        'Exam incoming! Remember: thermodynamics only goes one way—towards success. 📈',
        'Open your books before the examiner opens yours. 🔬',
      ];
      return quips[title.hashCode.abs() % quips.length];
    } else if (kind.contains('assignment') || kind.contains('submission')) {
      final quips = [
        'Deadline approaching at activation-energy speed—sprint! ⚡',
        'Submit now or face the wrath of the HOD. Your call. 😬',
        'That assignment won\'t submit itself. Unlike methane, it doesn\'t spontaneously combust. 💨',
        'Procrastination has a higher energy barrier than the assignment itself. Just do it. 🎯',
      ];
      return quips[title.hashCode.abs() % quips.length];
    } else if (kind.contains('study') || kind.contains('revision') || kind.contains('review')) {
      final quips = [
        'Your hippocampus is begging you to revise before the long-term potentiation fades. 🧠',
        'Even Le Chatelier shifts equilibrium when you study more. Get to it! ⚖️',
        'Study session time! The Gibbs free energy of ignorance is very positive. ❌',
        'Knowledge has zero half-life only if you keep reviewing it. Time to refresh! ♻️',
      ];
      return quips[title.hashCode.abs() % quips.length];
    } else if (kind.contains('lab') || kind.contains('practical')) {
      final quips = [
        'Safety goggles on, brain engaged, lab coat ready. Let\'s synthesise some knowledge! 🥼',
        'Lab time! Remember: fume hood ON, coffee cup away from reagents. ☕❌',
        'Practical session ahead. May your yields be high and your errors be systematic. 📊',
      ];
      return quips[title.hashCode.abs() % quips.length];
    } else {
      // Generic reminder — still witty
      final quips = [
        'You set this reminder for a reason. Your past self was smarter than you think. 🎓',
        'Don\'t ghost your own reminder. Your future exam marks are watching. 👀',
        'Ding! Your studious inner chemist is summoning you. Answer the call. 🔔',
        'This reminder is more urgent than a nucleophile attacking a carbonyl. Act fast! ⚡',
      ];
      return quips[title.hashCode.abs() % quips.length];
    }
  }

  Future<void> cancel(String id) => _plugin.cancel(id.hashCode);
}
