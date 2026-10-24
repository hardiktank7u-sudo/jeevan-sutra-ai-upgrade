// JeevanSutraBottomNavigation for Flutter
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

class JeevanSutraBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const JeevanSutraBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    final inactiveColor = isDark
        ? JeevanSutraColors.darkTextSecondary
        : JeevanSutraColors.secondaryText;

    final navItems = [
      _BottomNavItem(icon: Icons.home_rounded, label: "Home"),
      _BottomNavItem(icon: Icons.explore_rounded, label: "Explore"),
      _BottomNavItem(
        icon: Icons.document_scanner_rounded,
        label: "Scanner",
        isAccent: true,
      ),
      _BottomNavItem(icon: Icons.auto_awesome_rounded, label: "AI Guide"),
      _BottomNavItem(icon: Icons.person_rounded, label: "Profile"),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        border: Border(
          top: BorderSide(
            color: isDark
                ? JeevanSutraColors.darkBorder
                : JeevanSutraColors.subtleBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = currentIndex == index;

              if (item.isAccent) {
                // Elevated Scanner Button
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                JeevanSutraColors.freshLeaf,
                                JeevanSutraColors.deepBotanical,
                              ]
                            : [
                                JeevanSutraColors.forestGreen,
                                JeevanSutraColors.deepBotanical,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark
                                      ? JeevanSutraColors.freshLeaf
                                      : JeevanSutraColors.forestGreen)
                                  .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 16 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final bool isAccent;

  _BottomNavItem({
    required this.icon,
    required this.label,
    this.isAccent = false,
  });
}
