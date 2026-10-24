// Google AI Studio - Jeevan Sutra Health Profile Screen
// Complete botanical personalization, Prakriti diagnostics & AI health assessment
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/gemini_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import '../widgets/milestone_dialog.dart';
import 'about_screen.dart';
import 'dosha_assessment_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int refreshToken;
  final VoidCallback? onProfileChanged;

  const ProfileScreen({
    super.key,
    this.refreshToken = 0,
    this.onProfileChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  String _name = 'Wellness Explorer';
  String _ageGroup = '25–34';
  String _dominantPrakriti = 'Pitta-Kapha';
  String _dietaryPreference = 'Sattvic & Plant-Forward';
  int _streak = 7;

  int _savedWisdomCount = 0;
  int _savedPlantsCount = 0;
  List<String> _savedWisdom = [];
  List<String> _savedPlants = [];
  List<String> _completedHabits = [];

  bool _loading = true;
  bool _savedSuccess = false;

  final List<String> _prakritiOptions = [
    'Pitta-Vata',
    'Vata-Pitta',
    'Pitta-Kapha',
    'Kapha-Pitta',
    'Vata-Kapha',
    'Tridoshic (Balanced)',
    'Vata',
    'Pitta',
    'Kapha',
    'Kapha-Vata',
    'Tridoshic Balanced',
  ];

  final List<String> _ageGroups = ['18–24', '25–34', '35–44', '45–54', '55+'];

  final List<String> _diets = [
    'Sattvic & Plant-Forward',
    'Traditional Vegetarian',
    'Vegan & Ayurvedic',
    'Non-Vegetarian with Sattvic Principles',
  ];

  final List<Map<String, dynamic>> _dinacharyaHabits = [
    {'id': 'ushapan', 'title': 'Ushapan (Warm Water)', 'time': 'Dawn'},
    {
      'id': 'tongue_scrape',
      'title': 'Jihwa Nirlekhana (Oral Cleansing)',
      'time': 'Morning',
    },
    {'id': 'pranayama', 'title': 'Pranayama & Movement', 'time': 'Morning'},
    {
      'id': 'mindful_meal',
      'title': 'Mindful Ahara (Midday Meal)',
      'time': 'Midday',
    },
    {
      'id': 'evening_unwind',
      'title': 'Golden Milk & Digital Sunset',
      'time': 'Night',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final name = await LocalStorageService.instance.getProfileName();
    final dosha = await LocalStorageService.instance.getDosha();
    final streak = await LocalStorageService.instance.getStreak();
    final savedW = await LocalStorageService.instance.getSavedWisdom();
    final savedP = await LocalStorageService.instance.getSavedPlants();
    final habits = await LocalStorageService.instance.getCompletedHabits();

    if (!mounted) return;
    setState(() {
      if (name.isNotEmpty) {
        _name = name;
        _nameController.text = name;
      }
      if (dosha != null && dosha.isNotEmpty) _dominantPrakriti = dosha;
      _streak = streak > 0 ? streak : 7;
      _savedWisdom = savedW;
      _savedPlants = savedP;
      _savedWisdomCount = savedW.length;
      _savedPlantsCount = savedP.length;
      _completedHabits = habits;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await LocalStorageService.instance.saveProfileName(newName);
      await LocalStorageService.instance.saveDosha(_dominantPrakriti);
      if (!mounted) return;
      widget.onProfileChanged?.call();
      setState(() {
        _name = newName;
        _savedSuccess = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _savedSuccess = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile details updated successfully!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSavedModal(
    String title,
    List<String> items, {
    required bool isPlants,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? JeevanSutraColors.darkSurface
                : JeevanSutraColors.pureWhite,
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
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No saved items in this sanctuary yet.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                  ),
                )
              else
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isPlants ? Icons.eco_rounded : Icons.bookmark_rounded,
                        color: JeevanSutraColors.forestGreen,
                      ),
                      title: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _generateAiHealthReport() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final loadingDialog = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: JeevanSutraColors.warmIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: JeevanSutraColors.forestGreen),
              SizedBox(height: 16),
              Text(
                'Synthesizing Personal Ayurvedic Analysis...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: JeevanSutraColors.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    navigator.push(loadingDialog);

    final prompt =
        '''
Generate a personalized, uplifting, and research-backed Vedic Wellness Assessment for $_name.
Profile details:
- Constituent Dosha: $_dominantPrakriti
- Dietary Preference: $_dietaryPreference
- Daily Routine Streak: $_streak days
- Dinacharya habits completed today: ${_completedHabits.length} out of ${_dinacharyaHabits.length}

Provide:
1. 🌿 Constitution Insight (What their Dosha balance means)
2. 🍲 Food & Dietary Recommendations (Sattvic principles for their diet)
3. 🌅 Daily Rhythm Adjustment (One high-impact Dinacharya tip)
4. 🧘 Mind & Prana Practice (A calming breath or mindfulness technique)

Format with clean, inspiring Markdown with bullet points.
''';

    final stream = GeminiService.instance.streamChatResponse(
      prompt: prompt,
      conversationHistory: [],
    );

    StringBuffer fullResponse = StringBuffer();

    stream.listen(
      (chunk) {
        fullResponse.write(chunk);
      },
      onDone: () {
        if (!mounted) return;
        if (!loadingDialog.isCurrent) {
          if (loadingDialog.isActive) navigator.removeRoute(loadingDialog);
          return;
        }
        navigator.pop();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? JeevanSutraColors.darkSurface
                        : JeevanSutraColors.pureWhite,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? JeevanSutraColors.darkBorder
                                : JeevanSutraColors.subtleBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: JeevanSutraColors.mutedGold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Ayurvedic Health Synthesis",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? JeevanSutraColors.darkTextPrimary
                                      : JeevanSutraColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      MarkdownBody(
                        data: fullResponse.toString(),
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(ctx))
                            .copyWith(
                              p: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? JeevanSutraColors.darkTextPrimary
                                    : JeevanSutraColors.mainText,
                              ),
                              h1: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: JeevanSutraColors.forestGreen,
                              ),
                              h2: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: JeevanSutraColors.forestGreen,
                              ),
                            ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      onError: (err) {
        if (!mounted) return;
        if (loadingDialog.isActive) navigator.removeRoute(loadingDialog);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating report: $err")),
        );
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: JeevanSutraColors.forestGreen,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                _buildProfileOverviewCard(isDark),
                const SizedBox(height: 16),
                _buildEditableFormCard(isDark),
                const SizedBox(height: 16),
                _buildPrakritiTridoshicCard(isDark),
                const SizedBox(height: 16),
                _buildTapasyaStreakCard(isDark),
                const SizedBox(height: 16),
                _buildAiReportBanner(isDark),
                const SizedBox(height: 16),
                _buildSanctuaryItemsGrid(isDark),
                const SizedBox(height: 16),
                _buildSystemPreferences(isDark),
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
              Icons.person_rounded,
              size: 14,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "PERSONALIZATION",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark
                    ? JeevanSutraColors.freshLeaf
                    : JeevanSutraColors.forestGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "My Health Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark
                ? JeevanSutraColors.darkTextPrimary
                : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Your Prakriti constitution and bio-energetic goals inform personalized daily routines.",
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? JeevanSutraColors.darkTextSecondary
                : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Profile Overview Card ─────────────────────────────────────────────────

  Widget _buildProfileOverviewCard(bool isDark) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'H';

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        JeevanSutraColors.freshLeaf,
                        JeevanSutraColors.forestGreen,
                      ]
                    : [
                        JeevanSutraColors.forestGreen,
                        JeevanSutraColors.deepBotanical,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: JeevanSutraColors.forestGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.mainText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      "$_ageGroup yrs • ",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                    Text(
                      _dominantPrakriti,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: JeevanSutraColors.mutedGold,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Living Intelligence Activated",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: JeevanSutraColors.mutedGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Editable Form Card ────────────────────────────────────────────────────

  Widget _buildEditableFormCard(bool isDark) {
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
          Text(
            "Profile Details",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.darkTextPrimary
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 14),

          // Display Name
          Text(
            "Display Name",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
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
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? JeevanSutraColors.darkTextPrimary
                    : JeevanSutraColors.mainText,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Age Group Dropdown
          Text(
            "Age Range",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _ageGroup,
                isExpanded: true,
                dropdownColor: isDark
                    ? JeevanSutraColors.darkSurface
                    : JeevanSutraColors.pureWhite,
                items: _ageGroups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _ageGroup = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dominant Prakriti Dropdown
          Text(
            "Dominant Prakriti",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dominantPrakriti,
                isExpanded: true,
                dropdownColor: isDark
                    ? JeevanSutraColors.darkSurface
                    : JeevanSutraColors.pureWhite,
                // Keep quiz results and older saved values selectable instead
                // of passing a value absent from the dropdown's items.
                items: <String>{..._prakritiOptions, _dominantPrakriti}
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dominantPrakriti = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dietary Preference
          Text(
            "Dietary Lifestyle",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dietaryPreference,
                isExpanded: true,
                dropdownColor: isDark
                    ? JeevanSutraColors.darkSurface
                    : JeevanSutraColors.pureWhite,
                items: _diets
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dietaryPreference = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: JeevanSutraColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                _savedSuccess ? Icons.check_circle_rounded : Icons.save_rounded,
                size: 18,
              ),
              label: Text(
                _savedSuccess ? "Saved Successfully!" : "Save Profile Changes",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Prakriti Tridoshic Ratio Card ─────────────────────────────────────────

  Widget _buildPrakritiTridoshicCard(bool isDark) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tridoshic Balance Ratio",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.forestGreen,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoshaAssessmentScreen(
                        onBack: () => Navigator.pop(context),
                        onDoshaDetermined: (newDosha) {
                          if (!mounted) return;
                          setState(() => _dominantPrakriti = newDosha);
                          widget.onProfileChanged?.call();
                        },
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  "Retake Quiz",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.freshLeaf
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDoshaBar(
            "Vata (Air & Ether)",
            0.28,
            JeevanSutraColors.vataColor,
            "28%",
            isDark,
          ),
          const SizedBox(height: 8),
          _buildDoshaBar(
            "Pitta (Fire & Water)",
            0.44,
            JeevanSutraColors.pittaColor,
            "44%",
            isDark,
          ),
          const SizedBox(height: 8),
          _buildDoshaBar(
            "Kapha (Earth & Water)",
            0.28,
            JeevanSutraColors.kaphaColor,
            "28%",
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDoshaBar(
    String label,
    double ratio,
    Color color,
    String percent,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: isDark
                ? JeevanSutraColors.darkCanvas
                : JeevanSutraColors.softSage,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ─── Tapasya Streak & Consistency Card ─────────────────────────────────────

  Widget _buildTapasyaStreakCard(bool isDark) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_streak-Day Tapasya Streak",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Level 1 Agni Awakening achieved. Stoking cellular metabolic resilience.",
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
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onPressed: () => MilestoneCelebrationDialog.show(context, 7),
          ),
        ],
      ),
    );
  }

  // ─── AI Report Banner ──────────────────────────────────────────────────────

  Widget _buildAiReportBanner(bool isDark) {
    return InkWell(
      onTap: _generateAiHealthReport,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: JeevanSutraColors.freshLeaf,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Ayurvedic Assessment",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Synthesize your daily habits into personalized clinical guidance",
                    style: TextStyle(color: Color(0xFFBACBC1), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sanctuary Items Grid ──────────────────────────────────────────────────

  Widget _buildSanctuaryItemsGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showSavedModal(
              "Saved Wisdom & Articles",
              _savedWisdom,
              isPlants: false,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? JeevanSutraColors.darkSurface
                    : JeevanSutraColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? JeevanSutraColors.darkBorder
                      : JeevanSutraColors.subtleBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bookmark_rounded,
                    color: JeevanSutraColors.mutedGold,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_savedWisdomCount",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  Text(
                    "Saved Articles",
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _showSavedModal(
              "Saved Plants Herbarium",
              _savedPlants,
              isPlants: true,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? JeevanSutraColors.darkSurface
                    : JeevanSutraColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? JeevanSutraColors.darkBorder
                      : JeevanSutraColors.subtleBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: JeevanSutraColors.freshLeaf,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_savedPlantsCount",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  Text(
                    "Saved Plants",
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
          ),
        ),
      ],
    );
  }

  // ─── System & App Preferences ──────────────────────────────────────────────

  Widget _buildSystemPreferences(bool isDark) {
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
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System & Preferences",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? JeevanSutraColors.darkTextPrimary
                    : JeevanSutraColors.forestGreen,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.settings_rounded,
                color: JeevanSutraColors.forestGreen,
              ),
              title: const Text(
                "App Settings & Notifications",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.info_outline_rounded,
                color: JeevanSutraColors.forestGreen,
              ),
              title: const Text(
                "About Jeevan Sutra",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Version 1.0.0+1 (Living Intelligence)",
                style: TextStyle(fontSize: 10.5),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
