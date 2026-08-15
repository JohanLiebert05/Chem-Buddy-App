import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tzdata.initializeTimeZones();
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    ready = true;
  }

  Future<void> scheduleEvent(AcademicEvent event) async {
    if (!ready || event.completed) return;
    final when = tz.TZDateTime.from(event.dueDate, tz.local).subtract(const Duration(days: 1));
    final now = tz.TZDateTime.now(tz.local);
    final fire = when.isBefore(now)
        ? tz.TZDateTime.from(event.dueDate, tz.local).subtract(const Duration(hours: 2))
        : when.add(const Duration(hours: 9));
    if (fire.isBefore(now)) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chem_buddy_deadlines',
        'Tests & assignments',
        channelDescription: 'Reminders for upcoming chemistry deadlines',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      event.id.hashCode,
      '${event.type.name.toUpperCase()}: ${event.title}',
      'Due ${event.dueDate.year}-${event.dueDate.month.toString().padLeft(2, '0')}-${event.dueDate.day.toString().padLeft(2, '0')}',
      fire,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(String id) => _plugin.cancel(id.hashCode);
}
