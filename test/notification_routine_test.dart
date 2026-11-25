import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:jeevan_sutra/services/local_storage_service.dart';
import 'package:jeevan_sutra/services/notification_service.dart';

class FakeNotificationHost implements NotificationHost {
  bool initialized = false;
  bool permissionGranted = true;
  bool notificationsEnabled = true;
  bool scheduleSucceeds = true;
  int scheduleCount = 0;
  int cancelCount = 0;
  int? scheduledHour;
  int? scheduledMinute;

  @override
  Future<bool?> initialize() async {
    initialized = true;
    return true;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> schedule({required int hour, required int minute}) async {
    if (!scheduleSucceeds) throw StateError('scheduling failed');
    scheduleCount++;
    cancelCount++;
    scheduledHour = hour;
    scheduledMinute = minute;
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
  }
}

void main() {
  test('notification initialization succeeds', () async {
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    await service.init();

    expect(host.initialized, isTrue);
  });

  test('notification permission granted schedules daily reminder', () async {
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    final scheduled = await service.scheduleDailyReminder(hour: 7, minute: 30);

    expect(scheduled, isTrue);
    expect(host.scheduleCount, 1);
    expect(host.scheduledHour, 7);
    expect(host.scheduledMinute, 30);
  });

  test('notification permission denied does not schedule', () async {
    final host = FakeNotificationHost()..permissionGranted = false;
    final service = NotificationService(host: host);

    final scheduled = await service.scheduleDailyReminder(hour: 6, minute: 15);

    expect(scheduled, isFalse);
    expect(host.scheduleCount, 0);
  });

  test('changing reminder time cancels and replaces schedule', () async {
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    expect(await service.scheduleDailyReminder(hour: 6, minute: 0), isTrue);
    expect(await service.scheduleDailyReminder(hour: 9, minute: 54), isTrue);

    expect(host.scheduleCount, 2);
    expect(host.cancelCount, 2);
    expect(host.scheduledHour, 9);
    expect(host.scheduledMinute, 54);
  });

  test('saved reminder time is the time sent to the scheduler', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'notification_preference_initialized': true,
    });
    final storage = LocalStorageService.instance;
    await storage.saveNotificationTime(9, 54);
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    expect(
      await service.scheduleDailyReminder(
        hour: await storage.getNotificationHour(),
        minute: await storage.getNotificationMinute(),
      ),
      isTrue,
    );
    expect(host.scheduledHour, 9);
    expect(host.scheduledMinute, 54);
  });

  group('local reminder occurrence', () {
    late tz.Location location;

    setUpAll(() {
      tz_data.initializeTimeZones();
      location = tz.getLocation('Asia/Kolkata');
    });

    test('a reminder a few minutes ahead is scheduled for today locally', () {
      final now = tz.TZDateTime(location, 2026, 11, 19, 9, 52);

      final occurrence = PluginNotificationHost.nextReminderOccurrence(
        location: location,
        now: now,
        hour: 9,
        minute: 54,
      );

      expect(occurrence.year, 2026);
      expect(occurrence.month, 11);
      expect(occurrence.day, 19);
      expect(occurrence.hour, 9);
      expect(occurrence.minute, 54);
      expect(occurrence.timeZoneOffset, const Duration(hours: 5, minutes: 30));
    });

    test('a past reminder time is scheduled for the next local day', () {
      final now = tz.TZDateTime(location, 2026, 11, 19, 9, 55);

      final occurrence = PluginNotificationHost.nextReminderOccurrence(
        location: location,
        now: now,
        hour: 9,
        minute: 54,
      );

      expect(occurrence.year, 2026);
      expect(occurrence.month, 11);
      expect(occurrence.day, 20);
      expect(occurrence.hour, 9);
      expect(occurrence.minute, 54);
    });
  });

  test('cancel reminder uses the consistent notification ID', () async {
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    await service.cancelDailyReminder();

    expect(host.cancelCount, 1);
  });

  test('invalid reminder time is rejected', () async {
    final host = FakeNotificationHost();
    final service = NotificationService(host: host);

    expect(await service.scheduleDailyReminder(hour: 24, minute: 0), isFalse);
    expect(host.scheduleCount, 0);
  });

  test('new installation defaults reminders disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService.instance;

    expect(await storage.getNotificationsEnabled(), isFalse);
  });

  test('legacy saved reminder preference is preserved', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'notification_hour': 8,
      'notification_minute': 30,
    });
    final storage = LocalStorageService.instance;

    expect(await storage.getNotificationsEnabled(), isTrue);
    expect(await storage.getNotificationHour(), 8);
    expect(await storage.getNotificationMinute(), 30);
  });

  test('permission revocation disables stored preference', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'notification_preference_initialized': true,
    });
    final storage = LocalStorageService.instance;
    final host = FakeNotificationHost()..notificationsEnabled = false;
    final service = NotificationService(host: host);

    expect(await storage.getNotificationsEnabled(), isTrue);
    expect(await service.areNotificationsEnabled(), isFalse);
    if (!await service.areNotificationsEnabled()) {
      await storage.saveNotificationsEnabled(false);
      await service.cancelDailyReminder();
    }
    expect(await storage.getNotificationsEnabled(), isFalse);
  });

  test('scheduling failure does not report success', () async {
    final host = FakeNotificationHost()..scheduleSucceeds = false;
    final service = NotificationService(host: host);

    expect(await service.scheduleDailyReminder(hour: 6, minute: 0), isFalse);
    expect(host.cancelCount, 1);
  });

  group('routine tracking', () {
    test('one and multiple habits persist for one local date', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      final day = DateTime(2026, 11, 19, 23, 30);

      await storage.toggleDinacharyaTaskToday('rt_1', now: day);
      expect(await storage.getDinacharyaCompletedOn(day), ['rt_1']);

      await storage.saveCompletedHabitsForDate([
        'rt_1',
        'rt_2',
        'rt_2',
      ], now: day);
      expect(await storage.getDinacharyaCompletedOn(day), ['rt_1', 'rt_2']);
    });

    test('duplicate completion record is prevented', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      final day = DateTime(2026, 11, 19);
      const required = {'rt_1', 'rt_2'};

      await storage.saveCompletedHabitsForDate(['rt_1', 'rt_2'], now: day);
      expect(
        await storage.recordRoutineCompletionIfComplete(
          now: day,
          requiredHabits: required,
        ),
        1,
      );
      expect(
        await storage.recordRoutineCompletionIfComplete(
          now: day,
          requiredHabits: required,
        ),
        isNull,
      );
    });

    test('consecutive completed days create a streak', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      const required = {'rt_1', 'rt_2'};
      final day1 = DateTime(2026, 11, 18);
      final day2 = DateTime(2026, 11, 19);

      await storage.saveCompletedHabitsForDate(['rt_1', 'rt_2'], now: day1);
      await storage.recordRoutineCompletionIfComplete(
        now: day1,
        requiredHabits: required,
      );
      await storage.saveCompletedHabitsForDate(['rt_1', 'rt_2'], now: day2);
      await storage.recordRoutineCompletionIfComplete(
        now: day2,
        requiredHabits: required,
      );

      expect(await storage.getStreak(now: day2), 2);
    });

    test('missed day resets the streak', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      const required = {'rt_1', 'rt_2'};
      final day1 = DateTime(2026, 11, 17);
      final day2 = DateTime(2026, 11, 18);
      final missedDay = DateTime(2026, 11, 20);

      await storage.saveCompletedHabitsForDate(['rt_1', 'rt_2'], now: day1);
      await storage.recordRoutineCompletionIfComplete(
        now: day1,
        requiredHabits: required,
      );
      await storage.saveCompletedHabitsForDate(['rt_1', 'rt_2'], now: day2);
      await storage.recordRoutineCompletionIfComplete(
        now: day2,
        requiredHabits: required,
      );

      expect(await storage.getStreak(now: missedDay), 0);
    });

    test('empty history and restart have no invented streak', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      expect(await storage.getStreak(now: DateTime(2026, 11, 19)), 0);

      await storage.saveCompletedHabitsForDate([
        'rt_1',
      ], now: DateTime(2026, 11, 19));
      expect(
        await storage.getStreak(now: DateTime(2026, 11, 19)),
        0,
        reason: 'A partial day is not a completed routine.',
      );
    });

    test('7 and 30-day milestones are awarded once and persist', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;

      expect(await storage.markMilestoneShown(7), isTrue);
      expect(await storage.markMilestoneShown(7), isFalse);
      expect(await storage.markMilestoneShown(30), isTrue);
      expect(await storage.markMilestoneShown(30), isFalse);
      expect(await storage.markMilestoneShown(5), isFalse);
    });

    test('legacy milestone data remains compatible', () async {
      SharedPreferences.setMockInitialValues({
        'routine_shown_milestones': ['7'],
      });
      final storage = LocalStorageService.instance;

      expect(await storage.markMilestoneShown(7), isFalse);
      expect(await storage.markMilestoneShown(30), isTrue);
    });

    test('legacy saved streak is not invented', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;

      expect(await storage.getStreak(now: DateTime(2026, 11, 19)), 0);
    });
  });
}
