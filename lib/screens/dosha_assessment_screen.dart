// Flutter Implementation of Ayurvedic Dosha (Prakriti) Assessment Screen
// Comprehensive questionnaire with real-time scoring and personalized recommendations
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

import '../services/local_storage_service.dart';
import '../widgets/botanical_background.dart';

class DoshaAssessmentScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<String>? onDoshaDetermined;

  const DoshaAssessmentScreen({super.key, this.onBack, this.onDoshaDetermined});

  @override
  State<DoshaAssessmentScreen> createState() => _DoshaAssessmentScreenState();
}

class _AssessmentQuestion {
  final int id;
  final String category;
  final String title;
  final String vataOption;
  final String pittaOption;
  final String kaphaOption;

  const _AssessmentQuestion({
    required this.id,
    required this.category,
    required this.title,
    required this.vataOption,
    required this.pittaOption,
    required this.kaphaOption,
  });
}

class _DoshaAssessmentScreenState extends State<DoshaAssessmentScreen> {
  final List<_AssessmentQuestion> _questions = const [
    _AssessmentQuestion(
      id: 1,
      category: "PHYSICAL ANATOMY",
      title: "Body Frame & Skeletal Structure",
      vataOption: "Slender, light-boned, finds it hard to gain weight",
      pittaOption: "Medium, well-proportioned, athletic musculature",
      kaphaOption: "Broad, sturdy, solid frame, gains weight easily",
    ),
    _AssessmentQuestion(
      id: 2,
      category: "EPIDERMAL HEALTH",
      title: "Skin Texture & Complexion",
      vataOption: "Dry, rough, thin, easily cracks in colder weather",
      pittaOption: "Warm, reddish, sensitive, prone to freckles or acne",
      kaphaOption: "Thick, soft, supple, naturally moisturized and cool",
    ),
    _AssessmentQuestion(
      id: 3,
      category: "AGNI & DIGESTION",
      title: "Appetite, Digestion & Metabolism",
      vataOption: "Irregular, variable appetite, prone to gas or bloating",
      pittaOption: "Intense, sharp hunger; irritable if meals are delayed",
      kaphaOption: "Steady and slow; can easily skip meals without discomfort",
    ),
    _AssessmentQuestion(
      id: 4,
      category: "CIRCADIAN & NIDRA",
      title: "Sleep Quality & Patterns",
      vataOption: "Light, interrupted sleep; prone to vivid active dreams",
      pittaOption: "Moderate (6–7 hrs), sound sleep; wakes refreshed and alert",
      kaphaOption: "Deep, heavy, prolonged sleep; difficulty rising early",
    ),
    _AssessmentQuestion(
      id: 5,
      category: "MENTAL & EMOTIONAL",
      title: "Response to Stress & High Pressure",
      vataOption: "Anxiety, worry, racing thoughts, restlessness",
      pittaOption: "Impatience, frustration, irritation, perfectionism",
      kaphaOption: "Calm, withdraws, resistant to change, lethargic",
    ),
    _AssessmentQuestion(
      id: 6,
      category: "TEMPERATURE PREFERENCE",
      title: "Thermal Sensitivity & Weather Adaptability",
      vataOption: "Averse to cold, wind, and dry weather; loves warmth",
      pittaOption: "Averse to intense heat, humidity, and direct sun",
      kaphaOption: "Dislikes cold and damp climates; thrives in dry warmth",
    ),
  ];

  // Map question index to chosen dosha: 'vata', 'pitta', 'kapha'
  final Map<int, String> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isSubmitted = false;

  void _selectAnswer(String dosha) {
    setState(() {
      _answers[_currentQuestionIndex] = dosha;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _isSubmitted = true;
        _saveResult();
      }
    });
  }

  Future<void> _saveResult() async {
    final dominant = _calculateDominantPrakriti();
    await LocalStorageService.instance.saveDosha(dominant);
    if (!mounted) return;
    if (widget.onDoshaDetermined != null) {
      widget.onDoshaDetermined!(dominant);
    }
  }

  String _calculateDominantPrakriti() {
    int vataCount = 0;
    int pittaCount = 0;
    int kaphaCount = 0;

    _answers.forEach((_, dosha) {
      if (dosha == 'vata') vataCount++;
      if (dosha == 'pitta') pittaCount++;
      if (dosha == 'kapha') kaphaCount++;
    });

    if (vataCount > pittaCount && vataCount > kaphaCount) return "Vata";
    if (pittaCount > vataCount && pittaCount > kaphaCount) return "Pitta";
    if (kaphaCount > vataCount && kaphaCount > pittaCount) return "Kapha";
    if (pittaCount == vataCount && pittaCount > kaphaCount) return "Pitta-Vata";
    if (vataCount == kaphaCount && vataCount > pittaCount) return "Vata-Kapha";
    if (pittaCount == kaphaCount && pittaCount > vataCount) {
      return "Pitta-Kapha";
    }
    return "Tridoshic Balanced";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prakriti Dosha Assessment"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          child: _isSubmitted
              ? _buildResultsView(isDark)
              : _buildQuestionnaireView(isDark, primaryColor),
        ),
      ),
    );
  }

  Widget _buildQuestionnaireView(bool isDark, Color primaryColor) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final currentChoice = _answers[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "QUESTION ${_currentQuestionIndex + 1} OF ${_questions.length}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}% COMPLETED",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? JeevanSutraColors.darkSurfaceElevated
                      : JeevanSutraColors.softSage,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),

              // Question Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? JeevanSutraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JeevanSutraColors.darkTextPrimary
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Choice A: Vata
                    _buildOptionTile(
                      label: "Vata Tendency",
                      description: question.vataOption,
                      accentColor: JeevanSutraColors.vataColor,
                      isSelected: currentChoice == 'vata',
                      onTap: () => _selectAnswer('vata'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Choice B: Pitta
                    _buildOptionTile(
                      label: "Pitta Tendency",
                      description: question.pittaOption,
                      accentColor: JeevanSutraColors.pittaColor,
                      isSelected: currentChoice == 'pitta',
                      onTap: () => _selectAnswer('pitta'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Choice C: Kapha
                    _buildOptionTile(
                      label: "Kapha Tendency",
                      description: question.kaphaOption,
                      accentColor: JeevanSutraColors.kaphaColor,
                      isSelected: currentChoice == 'kapha',
                      onTap: () => _selectAnswer('kapha'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Back & Skip Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _currentQuestionIndex--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text("Previous Question"),
                    )
                  else
                    const SizedBox.shrink(),
                  TextButton(
                    onPressed: () => _selectAnswer('pitta'),
                    child: const Text("Skip for now"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String label,
    required String description,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark
                    ? JeevanSutraColors.darkCanvas
                    : JeevanSutraColors.warmIvory),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark
                      ? JeevanSutraColors.darkBorder
                      : JeevanSutraColors.subtleBorder),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : (isDark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }

  Widget _buildResultsView(bool isDark) {
    final dominant = _calculateDominantPrakriti();
    int vata = 0, pitta = 0, kapha = 0;
    _answers.forEach((_, d) {
      if (d == 'vata') vata++;
      if (d == 'pitta') pitta++;
      if (d == 'kapha') kapha++;
    });
    final total = _answers.isNotEmpty ? _answers.length : 1;
    final vataPct = ((vata / total) * 100).round();
    final pittaPct = ((pitta / total) * 100).round();
    final kaphaPct = ((kapha / total) * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            JeevanSutraColors.darkSurfaceElevated,
                            JeevanSutraColors.darkCanvas,
                          ]
                        : [
                            JeevanSutraColors.forestGreen,
                            JeevanSutraColors.deepBotanical,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.spa_rounded,
                      color: JeevanSutraColors.freshLeaf,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "YOUR PRAKRITI CONSTITUTION",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: JeevanSutraColors.freshLeaf,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dominant,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your foundational Ayurvedic blueprint discovered from classical treatises.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    // Dosha Percentage Breakdown Bar
                    Row(
                      children: [
                        _buildDoshaBadge(
                          "Vata",
                          "$vataPct%",
                          JeevanSutraColors.vataColor,
                        ),
                        const SizedBox(width: 8),
                        _buildDoshaBadge(
                          "Pitta",
                          "$pittaPct%",
                          JeevanSutraColors.pittaColor,
                        ),
                        const SizedBox(width: 8),
                        _buildDoshaBadge(
                          "Kapha",
                          "$kaphaPct%",
                          JeevanSutraColors.kaphaColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommendations Section
              Text(
                "Personalized Lifestyle Guidance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.forestGreen,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuidanceCard(
                icon: Icons.restaurant_outlined,
                title: "Dietary Principles (Ahara)",
                description: dominant.contains("Pitta")
                    ? "Favor cooling, sweet, and bitter foods. Moderate spicy, sour, and fermented spices. Drink coconut water and infuse mint."
                    : (dominant.contains("Vata")
                          ? "Favor warm, unctuous, grounding soups, cooked grains, ghee, and warming spices like ginger and cinnamon."
                          : "Favor light, pungent, bitter, and astringent foods. Enjoy roasted legumes and warm herbal teas."),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildGuidanceCard(
                icon: Icons.self_improvement_outlined,
                title: "Recommended Pranayama & Movement",
                description: dominant.contains("Pitta")
                    ? "Sheetali and Sheetkari cooling breathwork, gentle Moon Salutations, and evening nature strolls."
                    : (dominant.contains("Vata")
                          ? "Nadi Shodhana alternate nostril breathing, grounding slow flow asanas, and warm sesame oil Abhyanga."
                          : "Kapalabhati invigorating breathwork, dynamic Surya Namaskar, and brisk morning cardio."),
                isDark: isDark,
              ),
              const SizedBox(height: 28),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: JeevanSutraColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  "Apply Prakriti to My Profile",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _answers.clear();
                    _currentQuestionIndex = 0;
                    _isSubmitted = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Retake Assessment"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoshaBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkSurfaceElevated
                  : JeevanSutraColors.softSage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
    );
  }
}
