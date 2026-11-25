import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages real local notifications for Jeevan Sutra wellness reminders.
abstract interface class NotificationHost {
  Future<bool?> initialize();
  Future<bool> requestPermission();
  Future<bool> areNotificationsEnabled();
  Future<void> schedule({required int hour, required int minute});
  Future<void> cancel();
}

class PluginNotificationHost implements NotificationHost {
  final FlutterLocalNotificationsPlugin plugin;

  PluginNotificationHost({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<bool?> initialize() async {
    if (kIsWeb) return true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    return plugin.initialize(settings);
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> schedule({required int hour, required int minute}) async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    late final tz.Location location;
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      location = tz.getLocation(timezoneInfo.identifier);
    } catch (_) {
      throw StateError('Could not determine the device timezone.');
    }
    tz.setLocalLocation(location);

    await _cancelScheduledReminder();
    final scheduledDate = nextReminderOccurrence(
      location: location,
      now: tz.TZDateTime.now(location),
      hour: hour,
      minute: minute,
    );

    const androidDetails = AndroidNotificationDetails(
      'jeevan_sutra_wellness',
      'Wellness Reminders',
      channelDescription: 'Daily Jeevan Sutra wellness and habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await plugin.zonedSchedule(
      42,
      'Jeevan Sutra',
      'Time for your daily Dinacharya routine.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    final pending = await plugin.pendingNotificationRequests();
    if (!pending.any((request) => request.id == 42)) {
      throw StateError('The daily reminder was not registered as pending.');
    }
  }

  @visibleForTesting
  static tz.TZDateTime nextReminderOccurrence({
    required tz.Location location,
    required tz.TZDateTime now,
    required int hour,
    required int minute,
  }) {
    var occurrence = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!occurrence.isAfter(now)) {
      final nextDay = DateTime(now.year, now.month, now.day + 1);
      occurrence = tz.TZDateTime(
        location,
        nextDay.year,
        nextDay.month,
        nextDay.day,
        hour,
        minute,
      );
    }
    return occurrence;
  }

  Future<void> _cancelScheduledReminder() => plugin.cancel(42);

  @override
  Future<void> cancel() async {
    try {
      await plugin.cancel(42);
    } catch (_) {
      // Missing platform registration should not crash startup or settings.
    }
  }
}

class NotificationService {
  NotificationService({NotificationHost? host})
    : _host = host ?? PluginNotificationHost();

  static final NotificationService instance = NotificationService();
  final NotificationHost _host;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _host.initialize();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<bool> requestPermission() async {
    await _ensureInit();
    try {
      return await _host.requestPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    await _ensureInit();
    try {
      return await _host.areNotificationsEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> scheduleDailyReminder({
    int hour = 6,
    int minute = 0,
    bool requestPermissionIfNeeded = true,
  }) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;
    await _ensureInit();
    if (requestPermissionIfNeeded && !await requestPermission()) return false;
    try {
      await _host.schedule(hour: hour, minute: minute);
      return true;
    } catch (_) {
      try {
        await _host.cancel();
      } catch (_) {}
      return false;
    }
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInit();
    await _host.cancel();
  }

  Future<bool> scheduleDinacharyaReminders({
    int hour = 6,
    int minute = 0,
    bool requestPermissionIfNeeded = true,
  }) => scheduleDailyReminder(
    hour: hour,
    minute: minute,
    requestPermissionIfNeeded: requestPermissionIfNeeded,
  );

  Future<void> cancelAll() async => cancelDailyReminder();

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
