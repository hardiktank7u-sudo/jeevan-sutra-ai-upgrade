// Google AI Studio - Jeevan Sutra Ritucharya Screen
// 6 Classical Indian Seasons (Shad-Ritu) & Biometeorology
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class RitucharyaScreen extends StatefulWidget {
  const RitucharyaScreen({super.key});

  @override
  State<RitucharyaScreen> createState() => _RitucharyaScreenState();
}

class _RitucharyaScreenState extends State<RitucharyaScreen> {
  late SeasonInfo _selectedSeason;

  @override
  void initState() {
    super.initState();
    // Default to Vasanta (Spring) as in Google AI Studio
    _selectedSeason = SampleData.seasonInfos.firstWhere(
      (s) => s.type == SeasonType.vasanta,
      orElse: () => SampleData.seasonInfos.first,
    );
  }

  IconData _getSeasonIcon(SeasonType type) {
    switch (type) {
      case SeasonType.shishira:
        return Icons.ac_unit_rounded;
      case SeasonType.vasanta:
        return Icons.eco_rounded;
      case SeasonType.grishma:
        return Icons.wb_sunny_rounded;
      case SeasonType.varsha:
        return Icons.water_drop_rounded;
      case SeasonType.sharad:
        return Icons.air_rounded;
      case SeasonType.hemanta:
        return Icons.severe_cold_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSeasons = SampleData.seasonInfos;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Seasonal Wellness"),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
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
                _buildSeasonSelector(allSeasons, isDark),
                const SizedBox(height: 16),
                _buildActiveSeasonHero(_selectedSeason, isDark),
                const SizedBox(height: 16),
                _buildDoshaDynamicsCard(_selectedSeason, isDark),
                const SizedBox(height: 16),
                _buildDietaryGuidanceCard(_selectedSeason, isDark),
                const SizedBox(height: 16),
                _buildLifestyleGuidanceCard(_selectedSeason, isDark),
                const SizedBox(height: 16),
                _buildRecommendedHerbsCard(_selectedSeason, isDark),
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
              Icons.wb_sunny_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "BIOMETEOROLOGY & CLIMATE",
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
          "Ritucharya Guidance",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Harmonize biological humors with the 6 classical Indian astronomical seasons.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Season Selector Horizontal Scroll ─────────────────────────────────────

  Widget _buildSeasonSelector(List<SeasonInfo> seasons, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: seasons.map((season) {
          final isSelected = _selectedSeason.type == season.type;
          final icon = _getSeasonIcon(season.type);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : JeevanSutraColors.forestGreen),
              label: Text("${season.name} (${season.sanskritName})"),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedSeason = season);
              },
              backgroundColor: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
              selectedColor: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Active Season Hero Card ───────────────────────────────────────────────

  Widget _buildActiveSeasonHero(SeasonInfo season, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [JeevanSutraColors.darkSurfaceElevated, JeevanSutraColors.darkCanvas]
              : [JeevanSutraColors.forestGreen, JeevanSutraColors.deepBotanical],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: JeevanSutraColors.forestGreen.withValues(alpha: 0.25),
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
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  season.months.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: JeevanSutraColors.freshLeaf,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wb_sunny_rounded, size: 14, color: JeevanSutraColors.mutedGold),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      season.dominantElement,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: JeevanSutraColors.mutedGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${season.name} Ritu",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            season.sanskritName,
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFFBACBC1)),
          ),
          const SizedBox(height: 10),
          Text(season.doshaState, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFBACBC1))),
        ],
      ),
    );
  }

  // ─── Dosha Dynamics Card ───────────────────────────────────────────────────

  Widget _buildDoshaDynamicsCard(SeasonInfo season, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, size: 18, color: JeevanSutraColors.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Seasonal Dosha Dynamics",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            season.doshaState,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dietary Guidance Card ─────────────────────────────────────────────────

  Widget _buildDietaryGuidanceCard(SeasonInfo season, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 18, color: JeevanSutraColors.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Seasonal Ahara (Dietary Prescriptions)",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            season.dietaryAdvice,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            "AVOIDANCES & CONTRAINDICATIONS",
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: season.avoidances.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Lifestyle Guidance Card ───────────────────────────────────────────────

  Widget _buildLifestyleGuidanceCard(SeasonInfo season, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.self_improvement_rounded, size: 18, color: JeevanSutraColors.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Seasonal Vihara (Lifestyle & Regimen)",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            season.lifestyleAdvice,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recommended Herbs ─────────────────────────────────────────────────────

  Widget _buildRecommendedHerbsCard(SeasonInfo season, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurfaceElevated : JeevanSutraColors.softSage,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, size: 18, color: JeevanSutraColors.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Seasonal Botanical Allies",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: season.recommendedHerbs.map((herb) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa_rounded, size: 12, color: JeevanSutraColors.freshLeaf),
                    const SizedBox(width: 5),
                    Text(
                      herb,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
