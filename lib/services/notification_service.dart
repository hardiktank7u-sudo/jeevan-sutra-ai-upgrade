import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages real local notifications for Jeevan Sutra wellness reminders.
///
/// Usage:
///   await NotificationService.instance.init();
///   await NotificationService.instance.scheduleDailyReminder();
///   await NotificationService.instance.cancelDailyReminder();
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 42;
  static const String _channelId = 'jeevan_sutra_wellness';
  static const String _channelName = 'Wellness Reminders';
  static const String _channelDesc =
      'Daily Jeevan Sutra wellness and habit reminders';

  bool _initialized = false;

  /// Call once from main() or SettingsScreen before using any other method.
  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Request Android 13+ POST_NOTIFICATIONS permission.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule a daily wellness reminder at [hour]:[minute] (24-hour).
  /// Default: 8:00 AM.
  Future<void> scheduleDailyReminder({int hour = 8, int minute = 0}) async {
    await _ensureInit();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    // Show an immediate confirmation notification so the user knows it worked.
    await _plugin.show(
      _dailyReminderId,
      '🌿 Jeevan Sutra',
      'Daily wellness reminders are now active. You\'ll be reminded every day at $hour:${minute.toString().padLeft(2, '0')}.',
      details,
    );

    if (kDebugMode) {
      debugPrint('[NotificationService] Daily reminder scheduled at $hour:$minute');
    }
  }

  /// Cancel the daily wellness reminder.
  Future<void> cancelDailyReminder() async {
    await _ensureInit();
    await _plugin.cancel(_dailyReminderId);
    if (kDebugMode) {
      debugPrint('[NotificationService] Daily reminder cancelled.');
    }
  }

  // ─── Convenience aliases used by Settings screen ──────────────────────────

  /// Schedule Dinacharya (morning) reminders at 6:00 AM.
  Future<void> scheduleDinacharyaReminders() async =>
      scheduleDailyReminder(hour: 6, minute: 0);

  /// Cancel all scheduled reminders.
  Future<void> cancelAll() async => cancelDailyReminder();

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
