// Google AI Studio - Jeevan Sutra Dinacharya Screen
// 24-Hour Circadian Diurnal Timeline according to Charaka Samhita
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import '../widgets/milestone_dialog.dart';

class DinacharyaScreen extends StatefulWidget {
  const DinacharyaScreen({super.key});

  @override
  State<DinacharyaScreen> createState() => _DinacharyaScreenState();
}

class _DinacharyaScreenState extends State<DinacharyaScreen> {
  late List<RoutineItem> _routines;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _routines = SampleData.dailyRoutines;
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final completed = await LocalStorageService.instance.getCompletedHabits();
    if (!mounted) return;
    if (completed.isNotEmpty) {
      setState(() {
        for (var r in _routines) {
          if (completed.contains(r.id)) {
            r.isCompleted = true;
          }
        }
      });
    }
  }

  Future<void> _toggleRoutine(RoutineItem item) async {
    setState(() {
      item.isCompleted = !item.isCompleted;
    });
    final completedIds = _routines.where((r) => r.isCompleted).map((r) => r.id).toList();
    await LocalStorageService.instance.saveCompletedHabits(completedIds);
    if (completedIds.length == _routines.length) {
      if (mounted) MilestoneCelebrationDialog.show(context, 7);
    }
  }

  int get _completedCount => _routines.where((r) => r.isCompleted).length;
  double get _progress => _routines.isEmpty ? 0.0 : _completedCount / _routines.length;

  final List<Map<String, dynamic>> _periods = [
    {
      'key': RoutineTimeOfDay.morning,
      'label': 'Brahma & Morning (04:00 - 10:00)',
      'icon': Icons.wb_sunny_rounded,
      'color': JeevanSutraColors.mutedGold,
    },
    {
      'key': RoutineTimeOfDay.daytime,
      'label': 'Midday Pitta Solar (10:00 - 16:00)',
      'icon': Icons.light_mode_rounded,
      'color': JeevanSutraColors.forestGreen,
    },
    {
      'key': RoutineTimeOfDay.evening,
      'label': 'Sandhya Twilight (16:00 - 20:00)',
      'icon': Icons.wb_twilight_rounded,
      'color': JeevanSutraColors.freshLeaf,
    },
    {
      'key': RoutineTimeOfDay.night,
      'label': 'Nidra & Recovery (20:00 - 04:00)',
      'icon': Icons.nightlight_round,
      'color': JeevanSutraColors.deepBotanical,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Dinacharya Timeline"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                _buildProgressCard(isDark),
                const SizedBox(height: 20),
                ..._periods.map((period) {
                  final periodItems = _routines.where((r) => r.period == period['key']).toList();
                  if (periodItems.isEmpty) return const SizedBox.shrink();
                  return _buildPeriodSection(period, periodItems, isDark);
                }),
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
              Icons.schedule_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "CIRCADIAN CHRONOBIOLOGY",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Dinacharya Daily Routine",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Synchronize biological rhythms with natural light cues according to Charaka Samhita.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Progress Card ─────────────────────────────────────────────────────────

  Widget _buildProgressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Rhythm Adherence",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$_completedCount of ${_routines.length} Practices",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                    ),
                  ),
                ],
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "${(_progress * 100).round()}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Period Section with Vertical Timeline ─────────────────────────────────

  Widget _buildPeriodSection(Map<String, dynamic> period, List<RoutineItem> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(period['icon'] as IconData, size: 16, color: period['color'] as Color),
              const SizedBox(width: 8),
              Text(
                (period['label'] as String).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final isExpanded = _expandedId == item.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.isCompleted
                      ? JeevanSutraColors.freshLeaf.withValues(alpha: 0.5)
                      : (isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _toggleRoutine(item),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: item.isCompleted
                                ? (isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen)
                                : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    color: item.isCompleted
                                        ? (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText)
                                        : (isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.time} • ${item.sanskritName}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.balancingDosha.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedId = isExpanded ? null : item.id;
                              });
                            },
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 12),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.spa_rounded, size: 14, color: JeevanSutraColors.mutedGold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.benefits,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: JeevanSutraColors.mutedGold,
                                  ),
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
          }),
        ],
      ),
    );
  }
}
