import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// [ReminderService] backed by flutter_local_notifications.
///
/// Schedules one notification per weekday (7 total) so the message can
/// rotate while still repeating forever with no background work.
/// Uses inexact scheduling: no exact-alarm permission needed on Android.
final class LocalReminderService implements ReminderService {
  LocalReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'daily_ayah_reminder';
  static const int _baseId = 100;
  static const int _daysInWeek = 7;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC; reminders will still fire, just possibly shifted.
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return true;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute, required ReminderContent content}) async {
    await initialize();
    await cancelAll();
    if (content.bodies.isEmpty) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        content.channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (var i = 0; i < _daysInWeek; i++) {
      final weekday = DateTime.monday + i;
      await _plugin.zonedSchedule(
        _baseId + i,
        content.title,
        content.bodies[i % content.bodies.length],
        _nextInstance(weekday: weekday, hour: hour, minute: minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstance({required int weekday, required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = tz.TZDateTime(tz.local, date.year, date.month, date.day + 1, hour, minute);
    }
    return date;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
