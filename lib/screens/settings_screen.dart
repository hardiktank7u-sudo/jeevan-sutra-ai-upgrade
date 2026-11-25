// Google AI Studio - Jeevan Sutra Settings Screen
// Application preferences, Dinacharya notifications & profile configuration
import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  bool _notifications = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 0);
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionState();
    }
  }

  Future<void> _refreshPermissionState() async {
    if (!await LocalStorageService.instance.getNotificationsEnabled()) {
      if (mounted) setState(() => _notifications = false);
      return;
    }
    final granted = await NotificationService.instance
        .areNotificationsEnabled();
    if (!granted) {
      await LocalStorageService.instance.saveNotificationsEnabled(false);
      await NotificationService.instance.cancelAll();
      if (mounted) {
        setState(() => _notifications = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications were turned off in Android Settings. Enable them there, then enable reminders again in this app.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = LocalStorageService.instance;
    final name = await storage.getProfileName();
    final goal = await storage.getProfileGoal();
    final notifications = await storage.getNotificationsEnabled();
    final reminderHour = await storage.getNotificationHour();
    final reminderMinute = await storage.getNotificationMinute();
    var notificationEnabled = notifications;
    if (notificationEnabled) {
      final granted = await NotificationService.instance
          .areNotificationsEnabled();
      if (!granted) {
        notificationEnabled = false;
        await storage.saveNotificationsEnabled(false);
        await NotificationService.instance.cancelAll();
      }
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = name;
      _goalController.text = goal;
      _notifications = notificationEnabled;
      _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    setState(() => _saving = true);
    final storage = LocalStorageService.instance;
    await storage.saveProfileName(name);
    await storage.saveProfileGoal(goal);
    await storage.saveNotificationsEnabled(_notifications);
    await storage.saveNotificationTime(
      _reminderTime.hour,
      _reminderTime.minute,
    );

    var notificationSucceeded = true;
    if (_notifications) {
      final granted = await NotificationService.instance
          .areNotificationsEnabled();
      if (!granted) {
        notificationSucceeded = false;
      } else {
        notificationSucceeded = await NotificationService.instance
            .scheduleDinacharyaReminders(
              hour: _reminderTime.hour,
              minute: _reminderTime.minute,
              requestPermissionIfNeeded: false,
            );
      }
      if (!notificationSucceeded) {
        _notifications = false;
        await storage.saveNotificationsEnabled(false);
        await NotificationService.instance.cancelAll();
      }
    } else {
      await NotificationService.instance.cancelAll();
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationSucceeded ? 'Settings saved successfully.' : 'Notifications are unavailable. Reminders remain disabled. Enable notification permission in Android Settings, then try again.',
        ),
      ),
    );
  }

  Future<void> _onReminderToggle(bool enabled) async {
    final storage = LocalStorageService.instance;
    if (!enabled) {
      setState(() => _notifications = false);
      await storage.saveNotificationsEnabled(false);
      await NotificationService.instance.cancelAll();
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      await storage.saveNotificationsEnabled(false);
      await NotificationService.instance.cancelAll();
      if (mounted) {
        setState(() => _notifications = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. Reminders remain disabled. Enable them in Android Settings > Apps > Jeevan Sutra > Notifications.',
            ),
          ),
        );
      }
      return;
    }

    await storage.saveNotificationTime(
      _reminderTime.hour,
      _reminderTime.minute,
    );
    final scheduled = await NotificationService.instance
        .scheduleDinacharyaReminders(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          requestPermissionIfNeeded: false,
        );
    if (scheduled) {
      await storage.saveNotificationsEnabled(true);
      if (mounted) setState(() => _notifications = true);
    } else {
      await storage.saveNotificationsEnabled(false);
      await NotificationService.instance.cancelAll();
      if (mounted) {
        setState(() => _notifications = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminder scheduling failed. Reminders remain disabled.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JeevanSutraColors.warmIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Reset All Data?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: JeevanSutraColors.forestGreen,
          ),
        ),
        content: const Text(
          'This will reset your local profile, streak counter, and scan history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalStorageService.instance.clearAll();
      if (!mounted) return;
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data has been reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: JeevanSutraColors.forestGreen,
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 16),
                      _buildProfileSection(isDark),
                      const SizedBox(height: 16),
                      _buildNotificationsSection(isDark),
                      const SizedBox(height: 16),
                      _buildSaveButton(isDark),
                      const SizedBox(height: 24),
                      _buildDangerZone(isDark),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.settings_rounded,
              size: 14,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "PREFERENCES & SYSTEM",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Settings & Controls",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark
                ? JeevanSutraColors.darkTextPrimary
                : JeevanSutraColors.forestGreen,
          ),
        ),
      ],
    );
  }

  // ─── Profile Section ───────────────────────────────────────────────────────

  Widget _buildProfileSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account & Profile",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.darkTextPrimary
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Your Name",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkCanvas
                  : JeevanSutraColors.warmIvory,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 12.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Personal Wellness Focus",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkCanvas
                  : JeevanSutraColors.warmIvory,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
            ),
            child: TextField(
              controller: _goalController,
              style: const TextStyle(fontSize: 12.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notifications Section ─────────────────────────────────────────────────

  Widget _buildNotificationsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dinacharya Notifications",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.darkTextPrimary
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Circadian Rhythm Reminders",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Receive gentle alerts for Brahma Muhurta, Midday Agni, and Night Nidra",
                style: TextStyle(fontSize: 11),
              ),
              value: _notifications,
              activeThumbColor: JeevanSutraColors.forestGreen,
              onChanged: (val) => _onReminderToggle(val),
            ),
          ),
          if (_notifications) ...[
            const Divider(),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Daily reminder time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _reminderTime.format(context),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (selected != null && mounted) {
                    setState(() => _reminderTime = selected);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Save Button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: JeevanSutraColors.forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Save Preferences",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
      ),
    );
  }

  // ─── Danger Zone ───────────────────────────────────────────────────────────

  Widget _buildDangerZone(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBA1A1A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data & Reset",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBA1A1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Clear all saved preferences, scan records, and personalized Prakriti data from local storage.",
            style: TextStyle(
              fontSize: 11,
              color: JeevanSutraColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _clearAllData,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              side: const BorderSide(color: Color(0xFFBA1A1A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Reset All Application Data",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
