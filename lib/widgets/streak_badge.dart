// Consistency Streak Badge and Indicator Widget for Flutter
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

class ConsistencyStreakCard extends StatelessWidget {
  final int completedTasksCount;
  final int targetTasksCount;
  final VoidCallback? onMilestonesTap;

  const ConsistencyStreakCard({
    super.key,
    required this.completedTasksCount,
    this.targetTasksCount = 4,
    this.onMilestonesTap,
  });

  bool get isStreakActive => completedTasksCount >= targetTasksCount;
  int get streakDays => isStreakActive ? 8 : 7;
  int get tasksRemaining =>
      (targetTasksCount - completedTasksCount).clamp(0, targetTasksCount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    final amberColor = const Color(0xFFD97706);

    final weekDays = [
      {'label': 'M', 'completed': true},
      {'label': 'T', 'completed': true},
      {'label': 'W', 'completed': true},
      {'label': 'T', 'completed': true},
      {'label': 'F', 'completed': true},
      {'label': 'S', 'completed': true},
      {'label': 'S', 'completed': isStreakActive, 'isToday': true},
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
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isStreakActive
                      ? amberColor.withValues(alpha: 0.15)
                      : (isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: isStreakActive ? amberColor : primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Agni Consistency Streak",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? JeevanSutraColors.darkTextPrimary
                                : JeevanSutraColors.mainText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isStreakActive
                                ? amberColor.withValues(alpha: 0.15)
                                : (isDark
                                      ? JeevanSutraColors.darkCanvas
                                      : JeevanSutraColors.warmIvory),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isStreakActive
                                ? "Day 8 Unlocked"
                                : "$completedTasksCount/$targetTasksCount Today",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isStreakActive ? amberColor : primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isStreakActive
                          ? "Tapasya fulfilled today! Your biological Agni is steady."
                          : "Complete $tasksRemaining more task${tasksRemaining == 1 ? '' : 's'} to secure Day 8.",
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
              if (onMilestonesTap != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onPressed: onMilestonesTap,
                  tooltip: "View Streak Milestones",
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 7-Day Week Indicator Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkCanvas
                  : JeevanSutraColors.warmIvory,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((d) {
                      final isCompleted = d['completed'] as bool;
                      final isToday = d['isToday'] == true;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            d['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? primaryColor
                                  : (isToday
                                        ? Colors.transparent
                                        : (isDark
                                              ? JeevanSutraColors.darkBorder
                                              : JeevanSutraColors
                                                    .subtleBorder)),
                              border: isToday && !isCompleted
                                  ? Border.all(color: primaryColor, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : (isToday
                                        ? Text(
                                            "$completedTasksCount",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          )
                                        : null),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 14),
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark
                            ? JeevanSutraColors.darkBorder
                            : JeevanSutraColors.subtleBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$streakDays",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? JeevanSutraColors.freshLeaf
                              : JeevanSutraColors.forestGreen,
                        ),
                      ),
                      Text(
                        "Days Streak",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? JeevanSutraColors.darkTextSecondary
                              : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
