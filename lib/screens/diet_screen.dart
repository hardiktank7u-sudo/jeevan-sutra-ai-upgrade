// Google AI Studio - Jeevan Sutra Personalized Diet Screen
// Authentic Sattvic nourishment, Ahara Vidhi & hydration tracker
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  int _hydrationCups = 5;
  String _selectedDay = 'Today';
  String _selectedPreference = 'Sattvic';

  final List<String> _days = ['Mon', 'Tue', 'Today', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _preferences = ['Sattvic', 'Tridoshic', 'Plant-Forward', 'Gluten-Free'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meals = SampleData.mealSuggestions;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Personalized Diet"),
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
                _buildDaySelector(isDark),
                const SizedBox(height: 16),
                _buildHydrationTracker(isDark),
                const SizedBox(height: 20),
                _buildPreferenceChips(isDark),
                const SizedBox(height: 16),
                _buildMealSuggestions(meals, isDark),
                const SizedBox(height: 24),
                _buildAharaVidhiCard(isDark),
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
              Icons.restaurant_menu_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "AYURVEDIC NUTRITION",
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
          "Personalized Diet & Ahara",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Nourish your metabolic fire (Jatharagni) according to classical Ahara Vidhi.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Day Selector ──────────────────────────────────────────────────────────

  Widget _buildDaySelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: JeevanSutraColors.forestGreen),
                  const SizedBox(width: 6),
                  Text(
                    "Weekly Ahara Schedule",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                    ),
                  ),
                ],
              ),
              const Text(
                "Sama Agni Phase",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: JeevanSutraColors.freshLeaf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days.map((day) {
              final isSelected = _selectedDay == day;
              return InkWell(
                onTap: () => setState(() => _selectedDay = day),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen)
                        : (isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Hydration Tracker ─────────────────────────────────────────────────────

  Widget _buildHydrationTracker(bool isDark) {
    final progress = (_hydrationCups / 8.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded, size: 20, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Warm Water Ushapan",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                        ),
                      ),
                      Text(
                        "$_hydrationCups of 8 glasses (${_hydrationCups * 250} ml)",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 24),
                    onPressed: () {
                      if (_hydrationCups > 0) setState(() => _hydrationCups--);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, size: 28, color: JeevanSutraColors.forestGreen),
                    onPressed: () {
                      if (_hydrationCups < 12) setState(() => _hydrationCups++);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preference Filter Chips ───────────────────────────────────────────────

  Widget _buildPreferenceChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _preferences.map((pref) {
          final isSelected = _selectedPreference == pref;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(pref),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedPreference = pref);
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

  // ─── Meal Suggestions List ─────────────────────────────────────────────────

  Widget _buildMealSuggestions(List<MealSuggestion> meals, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DAILY NOURISHMENT TIMELINE",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...meals.map((meal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: JeevanSutraColors.mutedGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meal.mealType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: JeevanSutraColors.mutedGold,
                        ),
                      ),
                    ),
                    Text(
                      meal.timing,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  meal.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
                Text(
                  meal.sanskritName,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                  ),
                ),
                const Divider(height: 18),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: meal.ingredients.map((ing) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ing,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Ahara Vidhi (Rules of Classical Eating) ────────────────────────────────

  Widget _buildAharaVidhiCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurfaceElevated : JeevanSutraColors.softSage,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: JeevanSutraColors.forestGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                "Charaka Ahara Vidhi (Rules of Eating)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRuleItem("Ushnam Ashneeyat", "Eat warm, freshly cooked food to stoke digestive fire (Agni).", isDark),
          _buildRuleItem("Snigdham Ashneeyat", "Include healthy unctuous fats (pure A2 Ghee) for cellular absorption.", isDark),
          _buildRuleItem("Tanmana Bhunjeeta", "Eat with undivided attention, without screens or hurried movement.", isDark),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String sanskrit, String meaning, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: JeevanSutraColors.forestGreen)),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$sanskrit: ",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  TextSpan(
                    text: meaning,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
