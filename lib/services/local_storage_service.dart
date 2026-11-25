import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _profileNameKey = 'profile_name';
  static const String _profileGoalKey = 'profile_goal';
  static const String _savedWisdomKey = 'saved_wisdom';
  static const String _savedPlantsKey = 'saved_plants';
  static const String _savedPlantRecordsKey = 'saved_plant_records';
  static const String _scanHistoryKey = 'scan_history';
  static const String _chatHistoryKey = 'chat_history';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _notificationPreferenceInitializedKey =
      'notification_preference_initialized';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';
  static const String _firstLaunchKey = 'first_launch_complete';
  static const String _geminiApiKey = 'gemini_api_key';
  static const String _doshaKey = 'user_dosha';
  static const String _streakKey = 'wellness_streak';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _dinacharyaTasksKeyPrefix = 'dinacharya_tasks_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getDosha() async => (await _prefs).getString(_doshaKey);

  Future<void> saveDosha(String dosha) async {
    final prefs = await _prefs;
    await prefs.setString(_doshaKey, dosha);
  }

  static const String _routineStreakKey = 'routine_completion_streak';
  static const String _routineLastCompletedDateKey =
      'routine_last_completed_date';
  static const String _shownMilestonesKey = 'routine_shown_milestones';
  static const String _routineCompletedDatesKey = 'routine_completed_dates';

  static String _localDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<int> getNotificationHour() async =>
      (await _prefs).getInt(_notificationHourKey) ?? 6;

  Future<int> getNotificationMinute() async =>
      (await _prefs).getInt(_notificationMinuteKey) ?? 0;

  Future<void> saveNotificationTime(int hour, int minute) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return;
    final prefs = await _prefs;
    await prefs.setInt(_notificationHourKey, hour);
    await prefs.setInt(_notificationMinuteKey, minute);
  }

  Future<int> getStreak({DateTime? now}) async {
    final prefs = await _prefs;
    final today = now == null
        ? DateTime.now()
        : DateTime(now.year, now.month, now.day);
    final completedDates =
        prefs.getStringList(_routineCompletedDatesKey) ?? <String>[];
    if (completedDates.isNotEmpty) {
      var cursor = DateTime(today.year, today.month, today.day);
      if (!completedDates.contains(_localDateKey(cursor))) {
        cursor = cursor.subtract(const Duration(days: 1));
        if (!completedDates.contains(_localDateKey(cursor))) return 0;
      }
      var streak = 0;
      while (completedDates.contains(_localDateKey(cursor))) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    final lastDate = prefs.getString(_routineLastCompletedDateKey);
    if (lastDate == null) return 0;
    final todayKey = _localDateKey(today);
    final yesterdayKey = _localDateKey(today.subtract(const Duration(days: 1)));
    if (lastDate != todayKey && lastDate != yesterdayKey) return 0;
    return prefs.getInt(_routineStreakKey) ?? 0;
  }

  Future<int?> recordRoutineCompletionIfComplete({
    DateTime? now,
    Set<String>? requiredHabits,
  }) async {
    final prefs = await _prefs;
    final current = now == null
        ? DateTime.now()
        : DateTime(now.year, now.month, now.day);
    final today = _localDateKey(current);

    const legacyRequiredHabits = <String>{
      'ushapan',
      'tongue_scrape',
      'pranayama',
      'mindful_meal',
      'evening_unwind',
    };
    final required = requiredHabits ?? legacyRequiredHabits;

    final completed =
        prefs.getStringList('$_dinacharyaTasksKeyPrefix$today') ?? <String>[];
    if (!required.every(completed.contains)) return null;

    final completedDates =
        prefs.getStringList(_routineCompletedDatesKey) ?? <String>[];
    if (completedDates.contains(today)) return null;
    completedDates.insert(0, today);
    await prefs.setStringList(_routineCompletedDatesKey, completedDates);

    await prefs.setString(_routineLastCompletedDateKey, today);
    final nextStreak = await getStreak(now: current);
    await prefs.setInt(_routineStreakKey, nextStreak);
    return nextStreak;
  }

  Future<bool> markMilestoneShown(int days) async {
    if (days != 7 && days != 30) return false;

    final prefs = await _prefs;
    final shown = prefs.getStringList(_shownMilestonesKey) ?? <String>[];
    final key = days.toString();
    if (shown.contains(key)) return false;

    shown.add(key);
    await prefs.setStringList(_shownMilestonesKey, shown);
    return true;
  }

  Future<void> recordDailyActive() async {
    final prefs = await _prefs;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastActiveDateKey);

    if (lastDate == null) {
      await prefs.setString(_lastActiveDateKey, today);
      await prefs.setInt(_streakKey, 1);
      return;
    }

    if (lastDate == today) return;

    final last = DateTime.tryParse(lastDate);
    if (last != null) {
      final diff = DateTime.now().difference(last).inDays;
      final current = prefs.getInt(_streakKey) ?? 1;
      if (diff == 1) {
        await prefs.setInt(_streakKey, current + 1);
      } else {
        await prefs.setInt(_streakKey, 1);
      }
    }
    await prefs.setString(_lastActiveDateKey, today);
  }

  Future<List<String>> getDinacharyaCompletedToday() async {
    final prefs = await _prefs;
    final today = _localDateKey(DateTime.now());
    return prefs.getStringList('$_dinacharyaTasksKeyPrefix$today') ??
        <String>[];
  }

  Future<List<String>> getDinacharyaCompletedOn(DateTime date) async {
    final prefs = await _prefs;
    return prefs.getStringList(
          '$_dinacharyaTasksKeyPrefix${_localDateKey(date)}',
        ) ??
        <String>[];
  }

  Future<void> toggleDinacharyaTaskToday(String taskId, {DateTime? now}) async {
    final prefs = await _prefs;
    final current = now == null
        ? DateTime.now()
        : DateTime(now.year, now.month, now.day);
    final today = _localDateKey(current);
    final key = '$_dinacharyaTasksKeyPrefix$today';
    final list = prefs.getStringList(key) ?? <String>[];
    if (list.contains(taskId)) {
      list.remove(taskId);
    } else {
      list.add(taskId);
    }
    await prefs.setStringList(key, list);
  }

  Future<String?> getGeminiApiKey() async {
    final prefs = await _prefs;
    final key = prefs.getString(_geminiApiKey);
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    return null;
  }

  Future<void> saveGeminiApiKey(String? key) async {
    final prefs = await _prefs;
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_geminiApiKey);
    } else {
      await prefs.setString(_geminiApiKey, key.trim());
    }
  }

  Future<String> getProfileName() async =>
      (await _prefs).getString(_profileNameKey) ?? 'Wellness Explorer';

  Future<String> getProfileGoal() async =>
      (await _prefs).getString(_profileGoalKey) ?? 'Build mindful daily habits';

  Future<void> saveProfile({required String name, required String goal}) async {
    final prefs = await _prefs;
    await prefs.setString(
      _profileNameKey,
      name.trim().isEmpty ? 'Wellness Explorer' : name.trim(),
    );
    await prefs.setString(
      _profileGoalKey,
      goal.trim().isEmpty ? 'Build mindful daily habits' : goal.trim(),
    );
  }

  Future<List<String>> getSavedWisdom() async =>
      _getStringList(_savedWisdomKey);
  Future<List<String>> getSavedPlants() async {
    final prefs = await _prefs;
    final names = prefs.getStringList(_savedPlantsKey) ?? <String>[];
    final records = await getSavedPlantRecords();
    for (final plant in records) {
      if (plant.organismType != 'plant') continue;
      if (plant.confidence != null && plant.confidence! < 0.6) continue;
      if (!names.contains(plant.commonName)) {
        names.insert(0, plant.commonName);
      }
    }
    return names;
  }

  Future<void> toggleSavedWisdom(String title) async =>
      _toggleString(_savedWisdomKey, title);
  Future<void> toggleSavedPlant(String title) async {
    await _toggleString(_savedPlantsKey, title);
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedPlantRecordsKey) ?? <String>[];
    final remaining = <String>[];
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        if (decoded['commonName']?.toString() != title) remaining.add(item);
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setStringList(_savedPlantRecordsKey, remaining);
  }

  Future<void> savePlantRecord(Plant plant) async {
    final isConfirmedPlant =
        plant.organismType == 'plant' &&
        (plant.confidence == null || plant.confidence! >= 0.6);
    if (isConfirmedPlant) await savePlant(plant.commonName);
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedPlantRecordsKey) ?? <String>[];
    final records = <String>[];
    var replaced = false;
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        if (decoded['commonName']?.toString() == plant.commonName ||
            decoded['id']?.toString() == plant.id) {
          records.insert(0, jsonEncode(plant.toJson()));
          replaced = true;
        } else {
          records.add(item);
        }
      } catch (_) {
        records.add(item);
      }
    }
    if (!replaced) records.insert(0, jsonEncode(plant.toJson()));
    await prefs.setStringList(_savedPlantRecordsKey, records);
  }

  Future<List<Plant>> getSavedPlantRecords() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_savedPlantRecordsKey) ?? <String>[];
    final plants = <Plant>[];
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        final requiredName = decoded['commonName']?.toString();
        final requiredScientificName = decoded['scientificName']?.toString();
        if (requiredName == null || requiredScientificName == null) continue;
        plants.add(Plant.fromJson(decoded));
      } catch (_) {}
    }
    return plants;
  }

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_scanHistoryKey) ?? <String>[];
    return raw.map((item) {
      try {
        final decoded = jsonDecode(item);
        return Map<String, dynamic>.from(decoded as Map);
      } catch (_) {
        return <String, dynamic>{
          'name': item,
          'time': DateTime.now().toIso8601String(),
        };
      }
    }).toList();
  }

  Future<void> addScanHistory({
    required String fileName,
    String? plantName,
    double? confidence,
    Map<String, dynamic>? scanResult,
  }) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_scanHistoryKey) ?? <String>[];
    if (raw.isNotEmpty &&
        ((plantName != null && plantName.isNotEmpty) || scanResult != null)) {
      try {
        final top = Map<String, dynamic>.from(jsonDecode(raw.first) as Map);
        if (top['fileName'] == fileName &&
            (top['plantName'] == null || top['schemaVersion'] == null)) {
          top['name'] =
              plantName ?? scanResult?['plantName']?.toString() ?? top['name'];
          top['plantName'] = plantName ?? scanResult?['plantName'];
          if (confidence != null) top['confidence'] = confidence;
          if (scanResult != null) top.addAll(scanResult);
          if (scanResult != null) top['schemaVersion'] = 2;
          raw[0] = jsonEncode(top);
          await prefs.setStringList(_scanHistoryKey, raw);
          return;
        }
      } catch (_) {}
    }

    final entry = jsonEncode(<String, dynamic>{
      'schemaVersion': scanResult == null ? null : 2,
      'name': plantName != null && plantName.isNotEmpty
          ? plantName
          : scanResult?['plantName']?.toString() ?? fileName,
      'fileName': fileName,
      'plantName': plantName ?? scanResult?['plantName'],
      'confidence': confidence,
      'time': DateTime.now().toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
      ...?scanResult,
    });
    raw.insert(0, entry);
    if (raw.length > 20) {
      raw.removeRange(20, raw.length);
    }
    await prefs.setStringList(_scanHistoryKey, raw);
  }

  Future<void> clearScanHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_scanHistoryKey);
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_chatHistoryKey) ?? <String>[];
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      try {
        result.add(Map<String, dynamic>.from(jsonDecode(item) as Map));
      } catch (_) {}
    }
    return result;
  }

  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await _prefs;
    final trimmed = messages.length > 40
        ? messages.sublist(messages.length - 40)
        : messages;
    await prefs.setStringList(
      _chatHistoryKey,
      trimmed.map(jsonEncode).toList(),
    );
  }

  Future<void> clearChatHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_chatHistoryKey);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _prefs;
    if (prefs.containsKey(_notificationPreferenceInitializedKey)) {
      return prefs.getBool(_notificationsKey) ?? false;
    }
    // Backward compatibility: preserve an explicitly saved legacy preference.
    if (prefs.containsKey(_notificationsKey)) {
      final legacyValue = prefs.getBool(_notificationsKey) ?? false;
      await prefs.setBool(_notificationPreferenceInitializedKey, true);
      return legacyValue;
    }
    // Genuinely new installations start disabled.
    await prefs.setBool(_notificationPreferenceInitializedKey, true);
    await prefs.setBool(_notificationsKey, false);
    return false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_notificationPreferenceInitializedKey, true);
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<bool> isFirstLaunchComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_firstLaunchKey) ?? false;
  }

  Future<void> markFirstLaunchComplete() async {
    final prefs = await _prefs;
    await prefs.setBool(_firstLaunchKey, true);
  }

  // ─── Convenience aliases used by new Studio screens ─────────────────────────

  /// Alias for [saveProfile] accepting a single name field.
  Future<void> saveProfileName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(
      _profileNameKey,
      name.trim().isEmpty ? 'Wellness Explorer' : name.trim(),
    );
  }

  /// Alias for updating only the profile goal string.
  Future<void> saveProfileGoal(String goal) async {
    final prefs = await _prefs;
    await prefs.setString(
      _profileGoalKey,
      goal.trim().isEmpty ? 'Build mindful daily habits' : goal.trim(),
    );
  }

  /// Alias for [setNotificationsEnabled].
  Future<void> saveNotificationsEnabled(bool enabled) async =>
      setNotificationsEnabled(enabled);

  /// Alias for [toggleSavedWisdom] that adds (saves) the title.
  Future<void> saveWisdom(String title) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_savedWisdomKey) ?? <String>[];
    if (!list.contains(title)) {
      list.insert(0, title);
      await prefs.setStringList(_savedWisdomKey, list);
    }
  }

  /// Alias for [toggleSavedPlant] that adds (saves) the plant name.
  Future<void> savePlant(String name) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_savedPlantsKey) ?? <String>[];
    if (!list.contains(name)) {
      list.insert(0, name);
      await prefs.setStringList(_savedPlantsKey, list);
    }
  }

  /// Remove a plant from the saved list.
  Future<void> removePlant(String name) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_savedPlantsKey) ?? <String>[];
    list.remove(name);
    await prefs.setStringList(_savedPlantsKey, list);
    final raw = prefs.getStringList(_savedPlantRecordsKey) ?? <String>[];
    final remaining = <String>[];
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        if (decoded['commonName']?.toString() != name) remaining.add(item);
      } catch (_) {
        remaining.add(item);
      }
    }
    await prefs.setStringList(_savedPlantRecordsKey, remaining);
  }

  // ─── Completed habits (dinacharya / profile) ─────────────────────────────

  static const String _completedHabitsKey = 'completed_habits_general';

  /// Returns the list of completed habit IDs stored outside the date-keyed
  /// dinacharya tracker (used by profile screen summary).
  Future<List<String>> getCompletedHabits() async {
    final prefs = await _prefs;
    return prefs.getStringList(_completedHabitsKey) ?? <String>[];
  }

  /// Saves the list of completed habit IDs.
  Future<void> saveCompletedHabits(List<String> habits) async {
    final prefs = await _prefs;
    await prefs.setStringList(_completedHabitsKey, habits);
  }

  Future<void> saveCompletedHabitsForDate(
    List<String> habits, {
    DateTime? now,
  }) async {
    final prefs = await _prefs;
    final current = now == null
        ? DateTime.now()
        : DateTime(now.year, now.month, now.day);
    await prefs.setStringList(
      '$_dinacharyaTasksKeyPrefix${_localDateKey(current)}',
      habits.toSet().toList(),
    );
    await prefs.setStringList(_completedHabitsKey, habits.toSet().toList());
  }

  // ─── Clear all user data ──────────────────────────────────────────────────

  /// Clears ALL locally stored personal data including streaks and settings.
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<void> clearPersonalData() async {
    final prefs = await _prefs;
    for (final key in <String>[
      _profileNameKey,
      _profileGoalKey,
      _savedWisdomKey,
      _savedPlantsKey,
      _savedPlantRecordsKey,
      _scanHistoryKey,
      _chatHistoryKey,
      _notificationsKey,
      _notificationPreferenceInitializedKey,
      _notificationHourKey,
      _notificationMinuteKey,
      _routineStreakKey,
      _routineLastCompletedDateKey,
      _routineCompletedDatesKey,
      _shownMilestonesKey,
    ]) {
      await prefs.remove(key);
    }
  }

  Future<List<String>> _getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key) ?? <String>[];
  }

  Future<void> _toggleString(String key, String value) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(key) ?? <String>[];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.insert(0, value);
    }
    await prefs.setStringList(key, list);
  }
}
