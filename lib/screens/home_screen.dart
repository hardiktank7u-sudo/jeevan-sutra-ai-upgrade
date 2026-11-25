// Google AI Studio - Jeevan Sutra Home Screen
// Faithful botanical wellness interface implementation
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/affirmation_card.dart';
import '../widgets/botanical_background.dart';
import '../widgets/consistency_streak_badge.dart';
import '../widgets/milestone_dialog.dart';
import 'breathwork_session_screen.dart';
import 'diet_screen.dart';
import 'dinacharya_screen.dart';
import 'explore_screen.dart';
import 'knowledge_library_screen.dart';
import 'medicinal_plants_screen.dart';
import 'plant_detail_screen.dart';
import 'ritucharya_screen.dart';
import 'yoga_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Hardik';
  String _dominantPrakriti = 'Pitta-Kapha';
  int _hydrationCups = 5;
  int _mindfulnessMinutes = 15;
  int _currentStreakDays = 0;
  late List<RoutineItem> _routines;

  @override
  void initState() {
    super.initState();
    _routines = SampleData.dailyRoutines
        .map(
          (routine) => RoutineItem(
            id: routine.id,
            title: routine.title,
            sanskritName: routine.sanskritName,
            time: routine.time,
            period: routine.period,
            description: routine.description,
            benefits: routine.benefits,
            balancingDosha: routine.balancingDosha,
          ),
        )
        .toList();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await LocalStorageService.instance.getProfileName();
    final dosha = await LocalStorageService.instance.getDosha();
    final streak = await LocalStorageService.instance.getStreak();
    final completed = await LocalStorageService.instance
        .getDinacharyaCompletedToday();
    if (mounted) {
      setState(() {
        if (name.isNotEmpty && name != 'Wellness Explorer') {
          _userName = name.split(' ').first;
        }
        if (dosha != null && dosha.isNotEmpty) {
          _dominantPrakriti = dosha;
        }
        _currentStreakDays = streak;
        for (final routine in _routines) {
          routine.isCompleted = completed.contains(routine.id);
        }
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  int get _completedCount => _routines.where((r) => r.isCompleted).length;
  bool get _isTodayStreakAchieved =>
      _routines.isNotEmpty && _completedCount == _routines.length;
  int get _tasksRemainingForStreak =>
      (_routines.length - _completedCount).clamp(0, _routines.length);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BotanicalBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 16),
                _buildConsistencyStreakCard(isDark),
                const SizedBox(height: 16),
                AffirmationCard(
                  onBookmark: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Wisdom shloka saved to personal sanctuary.",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildHeroBanner(isDark),
                const SizedBox(height: 20),
                _buildDailyWellnessSnapshot(isDark),
                const SizedBox(height: 16),
                _buildBreathworkSanctuaryTile(isDark),
                const SizedBox(height: 16),
                _buildDinacharyaSection(isDark),
                const SizedBox(height: 24),
                _buildPillarsGrid(isDark),
                const SizedBox(height: 24),
                _buildRecommendations(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── A. Header & Streak Badge ──────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_rounded,
                    size: 14,
                    color: JeevanSutraColors.mutedGold,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "VASANTA RITU • MIDDAY ALIGNMENT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Namaste, $_userName",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.forestGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Your journey toward balanced living starts here.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? JeevanSutraColors.darkTextSecondary
                      : JeevanSutraColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        ConsistencyStreakBadge(
          completedTasks: _completedCount,
          totalRequired: _routines.length,
          baseStreakDays: _currentStreakDays,
          onTap: _currentStreakDays >= 7
              ? () => MilestoneCelebrationDialog.show(context, 7)
              : null,
        ),
      ],
    );
  }

  // ─── B. Agni Consistency Streak Detailed Indicator Card ────────────────────

  Widget _buildConsistencyStreakCard(bool isDark) {
    final weekDays = [
      {'label': 'M', 'completed': false, 'isToday': false},
      {'label': 'T', 'completed': false, 'isToday': false},
      {'label': 'W', 'completed': false, 'isToday': false},
      {'label': 'T', 'completed': false, 'isToday': false},
      {'label': 'F', 'completed': false, 'isToday': false},
      {'label': 'S', 'completed': false, 'isToday': false},
      {'label': 'S', 'completed': _isTodayStreakAchieved, 'isToday': true},
    ];

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
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _isTodayStreakAchieved
                      ? const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _isTodayStreakAchieved
                      ? null
                      : (isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: _isTodayStreakAchieved
                      ? Colors.white
                      : (isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Agni Consistency Streak",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? JeevanSutraColors.darkTextPrimary
                                : JeevanSutraColors.forestGreen,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _isTodayStreakAchieved
                                ? const Color(0xFFFEF3C7)
                                : (isDark
                                      ? JeevanSutraColors.darkCanvas
                                      : JeevanSutraColors.warmIvory),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isTodayStreakAchieved
                                ? 'Day $_currentStreakDays achieved'
                                : '$_completedCount/${_routines.length} Today',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isTodayStreakAchieved
                                  ? const Color(0xFF92400E)
                                  : (isDark
                                        ? JeevanSutraColors.darkTextSecondary
                                        : JeevanSutraColors.secondaryText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isTodayStreakAchieved
                          ? "Tapasya fulfilled for today! Your internal biological flame is steady."
                          : "Complete $_tasksRemainingForStreak more ${_tasksRemainingForStreak == 1 ? 'task' : 'tasks'} from Dinacharya.",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _currentStreakDays >= 7
                    ? () => MilestoneCelebrationDialog.show(context, 7)
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Milestones",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark
                          ? JeevanSutraColors.freshLeaf
                          : JeevanSutraColors.forestGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Day Indicators Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkCanvas
                  : JeevanSutraColors.warmIvory,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dayWidth = constraints.maxWidth / weekDays.length;
                      final indicatorSize = dayWidth < 28 ? dayWidth : 28.0;

                      return Row(
                        children: weekDays.map((day) {
                          final isCompleted = day['completed'] == true;
                          final isToday = day['isToday'] == true;

                          return SizedBox(
                            width: dayWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  day['label'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? JeevanSutraColors.darkTextSecondary
                                        : JeevanSutraColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: indicatorSize,
                                  height: indicatorSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? (isDark
                                              ? JeevanSutraColors.freshLeaf
                                              : JeevanSutraColors.forestGreen)
                                        : (isDark
                                              ? JeevanSutraColors.darkBorder
                                              : const Color(0xFFE4E8E0)),
                                    border: isToday && !isCompleted
                                        ? Border.all(
                                            color: isDark
                                                ? JeevanSutraColors.freshLeaf
                                                : JeevanSutraColors.forestGreen,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: indicatorSize < 24 ? 14 : 16,
                                            color: isDark
                                                ? JeevanSutraColors.darkCanvas
                                                : Colors.white,
                                          )
                                        : (isToday
                                              ? Text(
                                                  '$_completedCount',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? JeevanSutraColors
                                                              .freshLeaf
                                                        : JeevanSutraColors
                                                              .forestGreen,
                                                  ),
                                                )
                                              : null),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isToday ? 'Today' : '',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? JeevanSutraColors.freshLeaf
                                        : JeevanSutraColors.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: isDark
                      ? JeevanSutraColors.darkBorder
                      : JeevanSutraColors.subtleBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentStreakDays',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    Text(
                      'DAYS STREAK',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── C. Daily Living Intelligence Hero Banner ──────────────────────────────

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  JeevanSutraColors.darkSurfaceElevated,
                  JeevanSutraColors.darkCanvas,
                ]
              : [
                  JeevanSutraColors.forestGreen,
                  JeevanSutraColors.deepBotanical,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: JeevanSutraColors.forestGreen.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "DAILY LIVING INTELLIGENCE",
                  style: TextStyle(
                    color: JeevanSutraColors.freshLeaf,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                "Prakriti Sync • $_dominantPrakriti",
                style: const TextStyle(
                  color: Color(0xFFBACBC1),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"Small mindful choices create lasting balance."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Midday sun awakens maximum digestive fire (Jatharagni). Nourish your body with sattvic whole grains and light grounding herbs.",
            style: TextStyle(
              color: Color(0xFFBACBC1),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _navigateTo(const ExploreScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JeevanSutraColors.freshLeaf,
                  foregroundColor: JeevanSutraColors.deepBotanical,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Explore Today's Guidance",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _navigateTo(const DinacharyaScreen()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Timeline",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── D. Daily Wellness Snapshot (4-Card Metric Grid) ───────────────────────

  Widget _buildDailyWellnessSnapshot(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "DAILY WELLNESS SNAPSHOT",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
            Text(
              "Illustrative Metrics",
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark: isDark,
                icon: Icons.favorite_rounded,
                iconColor: JeevanSutraColors.freshLeaf,
                title: "Equilibrium",
                value: "88",
                unit: "/100",
                caption: "+4% vs yesterday",
                captionColor: JeevanSutraColors.freshLeaf,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? JeevanSutraColors.darkSurface
                      : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Hydration",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.water_drop_rounded,
                          size: 16,
                          color: Color(0xFF0284C7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_hydrationCups',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? JeevanSutraColors.darkTextPrimary
                                        : JeevanSutraColors.forestGreen,
                                  ),
                                ),
                                TextSpan(
                                  text: '/8 cups',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? JeevanSutraColors.darkTextSecondary
                                        : JeevanSutraColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (_hydrationCups > 0) {
                                  setState(() => _hydrationCups--);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? JeevanSutraColors.darkCanvas
                                      : JeevanSutraColors.warmIvory,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.remove, size: 14),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                if (_hydrationCups < 12) {
                                  setState(() => _hydrationCups++);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: JeevanSutraColors.forestGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_hydrationCups * 250} ml recorded",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                isDark: isDark,
                icon: Icons.nightlight_round,
                iconColor: JeevanSutraColors.mutedGold,
                title: "Restful Sleep",
                value: "7h 45m",
                unit: "",
                caption: "Deep REM: 2h 15m",
                captionColor: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? JeevanSutraColors.darkSurface
                      : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Mindfulness",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: JeevanSutraColors.freshLeaf,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_mindfulnessMinutes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? JeevanSutraColors.darkTextPrimary
                                        : JeevanSutraColors.forestGreen,
                                  ),
                                ),
                                TextSpan(
                                  text: ' mins',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? JeevanSutraColors.darkTextSecondary
                                        : JeevanSutraColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _mindfulnessMinutes += 5),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? JeevanSutraColors.darkCanvas
                                  : JeevanSutraColors.softSage,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "+5m",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: JeevanSutraColors.forestGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Goal: 20 mins/day",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: JeevanSutraColors.freshLeaf,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String caption,
    required Color captionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? JeevanSutraColors.darkTextSecondary
                        : JeevanSutraColors.secondaryText,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: captionColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── E. Somatic Breathwork Sanctuary Quick Launch Tile ─────────────────────

  Widget _buildBreathworkSanctuaryTile(bool isDark) {
    return InkWell(
      onTap: () => _navigateTo(const BreathworkSessionScreen()),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? JeevanSutraColors.darkSurfaceElevated
              : JeevanSutraColors.softSage,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? JeevanSutraColors.darkBorder
                : JeevanSutraColors.subtleBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: JeevanSutraColors.forestGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.air_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "PRANAYAMA STUDIO",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: JeevanSutraColors.forestGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: JeevanSutraColors.freshLeaf.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Active Engine",
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: JeevanSutraColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Somatic Breathwork Sanctuary",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.mainText,
                    ),
                  ),
                  Text(
                    "Box breathing & 4-7-8 vagal nerve calming guide with timer",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JeevanSutraColors.freshLeaf,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: JeevanSutraColors.deepBotanical,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── F. Dinacharya Routine Preview ─────────────────────────────────────────

  Widget _buildDinacharyaSection(bool isDark) {
    final previewItems = _routines.take(4).toList();
    final progress = _routines.isEmpty
        ? 0.0
        : _completedCount / _routines.length;

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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dinacharya Routine",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$_completedCount of ${_routines.length} completed (${(progress * 100).round()}%)",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateTo(const DinacharyaScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      "Full Timeline",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? JeevanSutraColors.darkCanvas
                  : JeevanSutraColors.softSage,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...previewItems.map((item) {
            return InkWell(
              onTap: () {
                setState(() {
                  item.isCompleted = !item.isCompleted;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      item.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: item.isCompleted
                          ? (isDark
                                ? JeevanSutraColors.freshLeaf
                                : JeevanSutraColors.forestGreen)
                          : (isDark
                                ? JeevanSutraColors.darkTextSecondary
                                : JeevanSutraColors.secondaryText),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCompleted
                                  ? (isDark
                                        ? JeevanSutraColors.darkTextSecondary
                                        : JeevanSutraColors.secondaryText)
                                  : (isDark
                                        ? JeevanSutraColors.darkTextPrimary
                                        : JeevanSutraColors.mainText),
                            ),
                          ),
                          Text(
                            "${item.time} • ${item.sanskritName}",
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? JeevanSutraColors.darkCanvas
                            : JeevanSutraColors.warmIvory,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.balancingDosha.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? JeevanSutraColors.freshLeaf
                              : JeevanSutraColors.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── G. Explore Pillars Grid ───────────────────────────────────────────────

  Widget _buildPillarsGrid(bool isDark) {
    final pillars = [
      {
        'title': 'Ayurveda & Wisdom',
        'screen': const ExploreScreen(),
        'icon': Icons.auto_awesome_rounded,
      },
      {
        'title': 'Nutrition & Diet',
        'screen': const DietScreen(),
        'icon': Icons.restaurant_menu_rounded,
      },
      {
        'title': 'Yoga & Meditation',
        'screen': const YogaScreen(),
        'icon': Icons.self_improvement_rounded,
      },
      {
        'title': 'Medicinal Plants',
        'screen': const MedicinalPlantsScreen(),
        'icon': Icons.eco_rounded,
      },
      {
        'title': 'Circadian Routine',
        'screen': const DinacharyaScreen(),
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'Seasonal Wellness',
        'screen': const RitucharyaScreen(),
        'icon': Icons.explore_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "EXPLORE PILLARS OF WELLNESS",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
            Text(
              "6 Domains",
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: cardWidth / 112,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: pillars.length,
              itemBuilder: (context, index) {
                final p = pillars[index];
                return InkWell(
                  onTap: () => _navigateTo(p['screen'] as Widget),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? JeevanSutraColors.darkSurface
                          : JeevanSutraColors.pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? JeevanSutraColors.darkBorder
                            : JeevanSutraColors.subtleBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? JeevanSutraColors.darkCanvas
                                : JeevanSutraColors.softSage,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            p['icon'] as IconData,
                            size: 18,
                            color: isDark
                                ? JeevanSutraColors.freshLeaf
                                : JeevanSutraColors.forestGreen,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p['title'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? JeevanSutraColors.darkTextPrimary
                                      : JeevanSutraColors.mainText,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ─── H. Recommendations for Dominant Prakriti ──────────────────────────────

  Widget _buildRecommendations(bool isDark) {
    final article = SampleData.knowledgeArticles.first;
    final plant = SampleData.medicinalPlants.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "RECOMMENDED FOR $_dominantPrakriti",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
            TextButton(
              onPressed: () => _navigateTo(const KnowledgeLibraryScreen()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: Text(
                "View All",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? JeevanSutraColors.freshLeaf
                      : JeevanSutraColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Article Card
        InkWell(
          onTap: () => _navigateTo(const KnowledgeLibraryScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkSurface
                  : JeevanSutraColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            article.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: JeevanSutraColors.mutedGold,
                            ),
                          ),
                          const Text(
                            " • ",
                            style: TextStyle(
                              color: JeevanSutraColors.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "${article.readingTimeMinutes} min read",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.mainText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        article.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? JeevanSutraColors.darkTextSecondary
                              : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? JeevanSutraColors.darkCanvas
                        : JeevanSutraColors.softSage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark
                        ? JeevanSutraColors.freshLeaf
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Plant Card
        InkWell(
          onTap: () => _navigateTo(PlantDetailScreen.fromMedicinalPlant(plant)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkSurface
                  : JeevanSutraColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "HERBAL ADAPTOGEN",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: JeevanSutraColors.freshLeaf,
                            ),
                          ),
                          const Text(
                            " • ",
                            style: TextStyle(
                              color: JeevanSutraColors.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            plant.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${plant.commonName} (${plant.sanskritName})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.mainText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${plant.primaryUses} — ${plant.traditionalApplication}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? JeevanSutraColors.darkTextSecondary
                              : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? JeevanSutraColors.darkCanvas
                        : JeevanSutraColors.softSage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark
                        ? JeevanSutraColors.freshLeaf
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
