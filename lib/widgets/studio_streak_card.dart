import 'package:flutter/material.dart';
import '../theme/jeevan_sutra_ui_theme.dart';


class ConsistencyStreakCard extends StatelessWidget {
  final int completedTasksCount;
  final int targetTasksCount;
  final int streakDays;
  final VoidCallback? onMilestonesTap;

  const ConsistencyStreakCard({
    super.key,
    required this.completedTasksCount,
    this.targetTasksCount = 5,
    this.streakDays = 0,
    this.onMilestonesTap,
  });

  int get tasksRemaining =>
      (targetTasksCount - completedTasksCount).clamp(0, targetTasksCount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    const amberColor = Color(0xFFD97706);
    final completedToday = completedTasksCount >= targetTasksCount;

    final today = DateTime.now();
    final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
                  color: completedToday
                      ? amberColor.withValues(alpha: 0.15)
                      : (isDark
                          ? JeevanSutraColors.darkSurfaceElevated
                          : JeevanSutraColors.softSage),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: completedToday ? amberColor : primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agni Consistency Streak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JeevanSutraColors.darkTextPrimary
                            : JeevanSutraColors.mainText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedTasksCount/$targetTasksCount tasks completed today',
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
                  tooltip: 'View Streak Milestones',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completedToday
                ? 'All daily habits completed. Wonderful consistency!'
                : 'Complete $tasksRemaining more task${tasksRemaining == 1 ? '' : 's'} to finish today’s routine.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
                    children: List.generate(7, (index) {
                      final day = today.subtract(Duration(
                        days: today.weekday - 1 - index,
                      ));
                      final isToday = index == today.weekday - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdayLabels[index],
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
                              color: isToday
                                  ? primaryColor.withValues(alpha: 0.12)
                                  : (isDark
                                      ? JeevanSutraColors.darkSurfaceElevated
                                      : JeevanSutraColors.subtleBorder),
                              border: isToday
                                  ? Border.all(
                                      color: primaryColor,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? primaryColor
                                      : (isDark
                                          ? JeevanSutraColors.darkTextSecondary
                                          : JeevanSutraColors.secondaryText),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
                        '$streakDays',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Day Streak',
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

