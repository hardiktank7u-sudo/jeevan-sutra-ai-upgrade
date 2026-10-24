// Consistency Streak Header Badge Component for Flutter with Pop Animation
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

class ConsistencyStreakBadge extends StatefulWidget {
  final int completedTasks;
  final int totalRequired;
  final int baseStreakDays;
  final VoidCallback? onTap;

  const ConsistencyStreakBadge({
    super.key,
    required this.completedTasks,
    this.totalRequired = 4,
    this.baseStreakDays = 7,
    this.onTap,
  });

  @override
  State<ConsistencyStreakBadge> createState() => _ConsistencyStreakBadgeState();
}

class _ConsistencyStreakBadgeState extends State<ConsistencyStreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;

  bool get isTodayAchieved => widget.completedTasks >= widget.totalRequired;
  int get currentStreak =>
      isTodayAchieved ? widget.baseStreakDays + 1 : widget.baseStreakDays;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60,
      ),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(covariant ConsistencyStreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedTasks > oldWidget.completedTasks) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = const Color(0xFFD97706);
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTodayAchieved
                  ? amberColor.withValues(alpha: 0.5)
                  : (isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder),
            ),
            color: isTodayAchieved
                ? amberColor.withValues(alpha: 0.12)
                : (isDark
                      ? JeevanSutraColors.darkSurface
                      : JeevanSutraColors.pureWhite),
            boxShadow: isTodayAchieved
                ? [
                    BoxShadow(
                      color: amberColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTodayAchieved
                      ? amberColor
                      : (isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: isTodayAchieved ? Colors.white : primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$currentStreak",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.mainText,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "Days",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.mainText,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isTodayAchieved
                        ? "Active 🔥"
                        : "${widget.completedTasks}/${widget.totalRequired} today",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isTodayAchieved
                          ? amberColor
                          : (isDark
                                ? JeevanSutraColors.darkTextSecondary
                                : JeevanSutraColors.secondaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
