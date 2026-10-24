// Google AI Studio - Jeevan Sutra Yoga & Meditation Screen
// Pranayama breath regulation, traditional asana vinyasas & Yoga Nidra
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import '../widgets/breathing_exercise.dart';
import 'breathwork_session_screen.dart';

class YogaScreen extends StatefulWidget {
  const YogaScreen({super.key});

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Morning Sun Salutations',
    'Vata Calming & Grounding',
    'Pitta Cooling Flow',
    'Yoga Nidra Deep Sleep',
  ];

  void _openSessionDetail(YogaMeditationSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: JeevanSutraColors.mutedGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                    session.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: JeevanSutraColors.mutedGold,
                      ),
                    ),
                  ),
                  Text(
                    "${session.durationMinutes} mins • ${session.intensity}",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                ),
              ),
              Text(
                session.sanskritTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                ),
              ),
              const Divider(height: 20),
              Text(
                session.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "PRIMARY BENEFIT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.modernBenefits,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: JeevanSutraColors.mutedGold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathworkSessionScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JeevanSutraColors.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                  label: const Text("Begin Guided Practice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = SampleData.yogaSessions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Yoga & Meditation"),
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
                _buildBreathworkSanctuaryTile(isDark),
                const SizedBox(height: 20),
                _buildEmbeddedBreathingWidget(isDark),
                const SizedBox(height: 24),
                _buildCategoryChips(isDark),
                const SizedBox(height: 16),
                _buildSessionsList(sessions, isDark),
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
              Icons.self_improvement_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "PRANAYAMA & ASANA",
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
          "Yoga & Meditation Sanctuary",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Pranayama breath regulation, traditional asana vinyasas, and Yoga Nidra.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Somatic Breathwork Sanctuary Tile ─────────────────────────────────────

  Widget _buildBreathworkSanctuaryTile(bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathworkSessionScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF174C3C), Color(0xFF10382E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: JeevanSutraColors.forestGreen.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.air_rounded, color: JeevanSutraColors.freshLeaf, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "FULL PRANAYAMA STUDIO",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: JeevanSutraColors.freshLeaf,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Somatic Breathwork Studio",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Box Breathing, 4-7-8 Vagal, & Sama Vritti with live timer",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBACBC1),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JeevanSutraColors.freshLeaf,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: JeevanSutraColors.deepBotanical),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Embedded Real-Time Breathing Exercise Widget ──────────────────────────

  Widget _buildEmbeddedBreathingWidget(bool isDark) {
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
              Text(
                "Quick Prana Alignment (Sama Vritti 4-4-4)",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                ),
              ),
              const Icon(Icons.spa_rounded, size: 18, color: JeevanSutraColors.freshLeaf),
            ],
          ),
          const SizedBox(height: 12),
          BreathingExerciseWidget(
            onCompleteSession: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Breathing cycle complete! Prana centered.")),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
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

  // ─── Sessions List ─────────────────────────────────────────────────────────

  Widget _buildSessionsList(List<YogaMeditationSession> sessions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "GUIDED SESSIONS (${sessions.length})",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.map((session) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _openSessionDetail(session),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.self_improvement_rounded, color: JeevanSutraColors.forestGreen, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${session.sanskritTitle} • ${session.durationMinutes} mins",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.modernBenefits,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: JeevanSutraColors.mutedGold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
