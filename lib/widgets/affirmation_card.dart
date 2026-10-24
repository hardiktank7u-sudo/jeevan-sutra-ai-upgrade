// Flutter Implementation of 'Affirmation of the Day'
// Rotating Ayurvedic & Vedic Wisdom with Sanskrit text and contemplation guidance
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

class AffirmationItem {
  final String shloka;
  final String translation;
  final String source;
  final String context;
  final String theme;

  const AffirmationItem({
    required this.shloka,
    required this.translation,
    required this.source,
    required this.context,
    required this.theme,
  });
}

class AffirmationCard extends StatefulWidget {
  final VoidCallback? onBookmark;

  const AffirmationCard({super.key, this.onBookmark});

  @override
  State<AffirmationCard> createState() => _AffirmationCardState();
}

class _AffirmationCardState extends State<AffirmationCard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isBookmarked = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<AffirmationItem> _wisdomItems = [
    AffirmationItem(
      shloka: "हितभुक् मितभुक् शाकभुक् च",
      translation: "Eat what is wholesome, eat in moderation, and eat plant-derived foods in seasonal rhythm.",
      source: "Charaka Samhita, Sutrasthana",
      context:
          "Ahara (Dietary Wisdom) for sustained Agni and cellular vitality",
      theme: "Nourishment & Agni",
    ),
    AffirmationItem(
      shloka: "समदोषः समाग्निश्च समधातुमलक्रियः। प्रसन्नात्मेन्द्रियमनाः स्वस्थ इत्यभिधीयते॥",
      translation: "One whose doshas are balanced, whose agni is balanced, whose tissues and wastes function normally, and whose soul, senses, and mind are clear and serene is termed 'Swastha' (truly healthy).",
      source: "Sushruta Samhita, Sutrasthana 15.41",
      context: "The classical definition of health transcends physical symptomlessness",
      theme: "Holistic Swastha",
    ),
    AffirmationItem(
      shloka: "शरीरमाद्यं खलु धर्मसाधनम्",
      translation: "The physical body is verily the foremost instrument for realizing higher purpose and righteous living.",
      source: "Kalidasa, Kumarasambhava 5.33",
      context: "Honor the vessel of your consciousness with daily Dinacharya",
      theme: "Sacred Embodiment",
    ),
    AffirmationItem(
      shloka: "युक्तस्वप्नावबोधस्य योगो भवति दुःखहा",
      translation: "For one who is temperate in sleep and wakefulness, yoga becomes the destroyer of sorrow.",
      source: "Bhagavad Gita 6.17",
      context: "Circadian rhythm alignment (Nidra & Brahma Muhurta)",
      theme: "Circadian Harmony",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextWisdom() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _wisdomItems.length;
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _wisdomItems[_currentIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : const Color(0xFFFBF9F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.mutedGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Meta Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: isDark
                            ? JeevanSutraColors.mutedGold
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "AFFIRMATION OF THE DAY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? JeevanSutraColors.mutedGold
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: _isBookmarked
                            ? JeevanSutraColors.mutedGold
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: "Bookmark wisdom",
                      onPressed: () {
                        setState(() => _isBookmarked = !_isBookmarked);
                        widget.onBookmark?.call();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      tooltip: "Next Wisdom Shloka",
                      onPressed: _nextWisdom,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sanskrit Shloka Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkCanvas : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? JeevanSutraColors.darkBorder
                      : const Color(0xFFE8E5DA),
                ),
              ),
              child: Text(
                item.shloka,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.forestGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // English Translation
            Text(
              "\"${item.translation}\"",
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? JeevanSutraColors.darkTextPrimary
                    : JeevanSutraColors.mainText,
              ),
            ),
            const SizedBox(height: 10),

            // Source Attribution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.source,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? JeevanSutraColors.mutedGold
                        : const Color(0xFF9A7B38),
                  ),
                ),
                Text(
                  item.theme,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
    );
  }
}
