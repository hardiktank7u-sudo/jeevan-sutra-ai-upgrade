import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _profileNameKey = 'profile_name';
  static const String _profileGoalKey = 'profile_goal';
  static const String _savedWisdomKey = 'saved_wisdom';
  static const String _savedPlantsKey = 'saved_plants';
  static const String _scanHistoryKey = 'scan_history';
  static const String _chatHistoryKey = 'chat_history';
  static const String _notificationsKey = 'notifications_enabled';
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

  Future<int> getStreak() async {
    final prefs = await _prefs;
    final lastDate = prefs.getString(_routineLastCompletedDateKey);
    if (lastDate == null) return 0;

    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final yesterday =
        now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    if (lastDate != today && lastDate != yesterday) return 0;
    return prefs.getInt(_routineStreakKey) ?? 0;
  }

  Future<int?> recordRoutineCompletionIfComplete() async {
    final prefs = await _prefs;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    const requiredHabits = <String>{
      'ushapan',
      'tongue_scrape',
      'pranayama',
      'mindful_meal',
      'evening_unwind',
    };

    final completed =
        prefs.getStringList('$_dinacharyaTasksKeyPrefix$today') ?? <String>[];
    if (!requiredHabits.every(completed.contains)) return null;

    final lastDate = prefs.getString(_routineLastCompletedDateKey);
    if (lastDate == today) return null;

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final previousStreak = prefs.getInt(_routineStreakKey) ?? 0;
    final nextStreak = lastDate == yesterday ? previousStreak + 1 : 1;

    await prefs.setInt(_routineStreakKey, nextStreak);
    await prefs.setString(_routineLastCompletedDateKey, today);
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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getStringList('$_dinacharyaTasksKeyPrefix$today') ?? <String>[];
  }

  Future<void> toggleDinacharyaTaskToday(String taskId) async {
    final prefs = await _prefs;
    final today = DateTime.now().toIso8601String().substring(0, 10);
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
    await prefs.setString(_profileNameKey, name.trim().isEmpty ? 'Wellness Explorer' : name.trim());
    await prefs.setString(_profileGoalKey, goal.trim().isEmpty ? 'Build mindful daily habits' : goal.trim());
  }

  Future<List<String>> getSavedWisdom() async => _getStringList(_savedWisdomKey);
  Future<List<String>> getSavedPlants() async => _getStringList(_savedPlantsKey);

  Future<void> toggleSavedWisdom(String title) async => _toggleString(_savedWisdomKey, title);
  Future<void> toggleSavedPlant(String title) async => _toggleString(_savedPlantsKey, title);

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_scanHistoryKey) ?? <String>[];
    return raw.map((item) {
      try {
        final decoded = jsonDecode(item);
        return Map<String, dynamic>.from(decoded as Map);
      } catch (_) {
        return <String, dynamic>{'name': item, 'time': DateTime.now().toIso8601String()};
      }
    }).toList();
  }

  Future<void> addScanHistory({required String fileName}) async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_scanHistoryKey) ?? <String>[];
    final entry = jsonEncode(<String, dynamic>{
      'name': fileName,
      'time': DateTime.now().toIso8601String(),
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
    final trimmed = messages.length > 40 ? messages.sublist(messages.length - 40) : messages;
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
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
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
      _scanHistoryKey,
      _chatHistoryKey,
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
