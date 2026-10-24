// JeevanSutraAppBar & JeevanSutraDrawer for Flutter
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

import '../models/wellness_models.dart';

class JeevanSutraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final Widget? trailingAction;

  const JeevanSutraAppBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    this.onSearchPressed,
    this.onProfilePressed,
    this.trailingAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26),
        tooltip: "Open Navigation Menu",
        onPressed: onMenuPressed,
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant Leaf / Sprout Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkSurfaceElevated
                  : JeevanSutraColors.softSage,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_rounded,
              size: 16,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? JeevanSutraColors.darkTextPrimary
                    : JeevanSutraColors.forestGreen,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onSearchPressed != null)
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 24),
            tooltip: "Search",
            onPressed: onSearchPressed,
          ),
        ?trailingAction,
        if (onProfilePressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: onProfilePressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.mutedGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  color: isDark
                      ? JeevanSutraColors.darkSurfaceElevated
                      : JeevanSutraColors.forestGreen,
                ),
                child: const Center(
                  child: Text(
                    "H",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class JeevanSutraDrawer extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onSelectDestination;
  final UserProfile profile;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const JeevanSutraDrawer({
    super.key,
    required this.currentRoute,
    required this.onSelectDestination,
    required this.profile,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width * 0.85;

    return Drawer(
      width: width.clamp(280.0, 360.0),
      backgroundColor: isDark
          ? JeevanSutraColors.darkSurface
          : JeevanSutraColors.pureWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header with Brand & User Profile Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? JeevanSutraColors.darkSurfaceElevated
                              : JeevanSutraColors.softSage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          color: isDark
                              ? JeevanSutraColors.freshLeaf
                              : JeevanSutraColors.forestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jeevan Sutra",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? JeevanSutraColors.darkTextPrimary
                                    : JeevanSutraColors.forestGreen,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              "Ancient Wisdom. Living Science.",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? JeevanSutraColors.darkTextSecondary
                                    : JeevanSutraColors.secondaryText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Compact User Card
                  Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: JeevanSutraColors.forestGreen,
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0] : "H",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Namaste, ${profile.name}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark
                                      ? JeevanSutraColors.darkTextPrimary
                                      : JeevanSutraColors.mainText,
                                ),
                              ),
                              Text(
                                "Prakriti: ${profile.dominantPrakriti}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? JeevanSutraColors.freshLeaf
                                      : JeevanSutraColors.forestGreen,
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
            ),

            const Divider(),

            // Scrollable Navigation List with Staggered Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _buildSectionHeader("MAIN", isDark),
                  _buildNavItem(Icons.home_outlined, "Home", "home", isDark),
                  _buildNavItem(
                    Icons.explore_outlined,
                    "Explore Wellness",
                    "explore",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.restaurant_outlined,
                    "Personalized Diet",
                    "diet",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.self_improvement_outlined,
                    "Yoga & Meditation",
                    "yoga",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.spa_outlined,
                    "Dosha Assessment",
                    "dosha_assessment",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.air_rounded,
                    "Breathwork Sanctuary",
                    "breathwork",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.schedule_outlined,
                    "Daily Routine",
                    "dinacharya",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.wb_sunny_outlined,
                    "Seasonal Wellness",
                    "ritucharya",
                    isDark,
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader("AI & DISCOVERY", isDark),
                  _buildNavItem(
                    Icons.auto_awesome_outlined,
                    "AI Wellness Assistant",
                    "ai_assistant",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.document_scanner_outlined,
                    "Plant Scanner",
                    "scanner",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.local_florist_outlined,
                    "Medicinal Plants",
                    "plants",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.auto_stories_outlined,
                    "Knowledge Library",
                    "library",
                    isDark,
                  ),

                  const SizedBox(height: 12),
                  _buildSectionHeader("PERSONAL", isDark),
                  _buildNavItem(
                    Icons.person_outline,
                    "My Health Profile",
                    "profile",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.bookmark_outline,
                    "Saved Items",
                    "saved",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.insights_outlined,
                    "Wellness Progress",
                    "progress",
                    isDark,
                  ),
                  _buildNavItem(
                    Icons.settings_outlined,
                    "Settings",
                    "settings",
                    isDark,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Footer with Version & Theme Switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Jeevan Sutra v1.2.0",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                      color: isDark
                          ? JeevanSutraColors.mutedGold
                          : JeevanSutraColors.forestGreen,
                    ),
                    tooltip: isDarkMode
                        ? "Switch to Light Theme"
                        : "Switch to Dark Theme",
                    onPressed: onToggleTheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool Brightometer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark
              ? JeevanSutraColors.darkTextSecondary
              : JeevanSutraColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String route, bool isDark) {
    final isSelected = currentRoute == route;
    final activeBg = isDark
        ? JeevanSutraColors.freshLeaf.withValues(alpha: 0.18)
        : JeevanSutraColors.softSage;
    final activeColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    final inactiveColor = isDark
        ? JeevanSutraColors.darkTextPrimary
        : JeevanSutraColors.mainText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectDestination(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? activeColor
                      : inactiveColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
