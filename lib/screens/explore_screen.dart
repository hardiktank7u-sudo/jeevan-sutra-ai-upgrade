// Google AI Studio - Jeevan Sutra Explore Screen
// Classical discovery and chronobiology editorial exploration
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import 'ai_screen.dart';
import 'dosha_assessment_screen.dart';
import 'knowledge_library_screen.dart';
import 'plant_detail_screen.dart';
import 'scanner_screen.dart';
import 'medicinal_plants_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Ayurveda & Traditional Wisdom',
    'Scientific Wellness',
    'Yoga & Meditation',
    'Adaptogens',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticle(KnowledgeArticle article) {
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
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ListView(
                controller: controller,
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
                          article.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: JeevanSutraColors.mutedGold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "By ${article.author} • ${article.readingTimeMinutes} min read",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    article.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: article.tags.map((t) {
                      return Chip(
                        label: Text("#$t"),
                        labelStyle: const TextStyle(fontSize: 11),
                        backgroundColor: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredArticles = SampleData.knowledgeArticles.where((art) {
      final matchesCategory = _selectedCategory == 'All' || art.category == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          art.title.toLowerCase().contains(query) ||
          art.excerpt.toLowerCase().contains(query) ||
          art.tags.any((t) => t.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    final filteredPlants = SampleData.medicinalPlants.where((p) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.commonName.toLowerCase().contains(query) ||
          p.botanicalName.toLowerCase().contains(query) ||
          p.primaryUses.toLowerCase().contains(query);
      return (_selectedCategory == 'All' || _selectedCategory == 'Adaptogens') && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                _buildSearchBar(isDark),
                const SizedBox(height: 12),
                _buildCategoryChips(isDark),
                const SizedBox(height: 16),
                if (_selectedCategory == 'All' && _searchQuery.isEmpty) ...[
                  _buildFeaturedEditorial(isDark),
                  const SizedBox(height: 20),
                  _buildQuickAccessSection(isDark),
                  const SizedBox(height: 20),
                ],
                _buildArticlesStream(filteredArticles, isDark),
                const SizedBox(height: 24),
                _buildBotanicalAdaptogens(filteredPlants, isDark),
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
              Icons.explore_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "VEDIC DISCOVERY",
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
          "Explore Wellness",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Discover classical treatises, chronobiology breakthroughs, and botanical solutions.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 12.5,
          color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
        ),
        decoration: InputDecoration(
          hintText: "Search doshas, herbs, pranayama, chronobiology...",
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Featured Editorial Collection Card ────────────────────────────────────

  Widget _buildFeaturedEditorial(bool isDark) {
    final article = SampleData.knowledgeArticles.first;

    return InkWell(
      onTap: () => _openArticle(article),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10382E), Color(0xFF174C3C), Color(0xFF10382E)],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: JeevanSutraColors.mutedGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "FEATURED EDITORIAL",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: JeevanSutraColors.mutedGold,
                    ),
                  ),
                ),
                Text(
                  "${article.readingTimeMinutes} min read",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBACBC1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFBACBC1),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "By ${article.author}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: JeevanSutraColors.mutedGold,
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      "Read Treatise",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: JeevanSutraColors.freshLeaf,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: JeevanSutraColors.freshLeaf),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Fast-Lane Action Cards ────────────────────────────────────────────────

  Widget _buildQuickAccessSection(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            isDark: isDark,
            title: "AI Wellness Guide",
            subtitle: "Consult Living Intelligence",
            icon: Icons.auto_awesome_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            isDark: isDark,
            title: "Plant Scanner",
            subtitle: "Diagnose botanical flora",
            icon: Icons.camera_alt_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            isDark: isDark,
            title: "Dosha Quiz",
            subtitle: "Prakriti Assessment",
            icon: Icons.balance_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoshaAssessmentScreen(onBack: () => Navigator.pop(context))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Articles & Monographs Stream ──────────────────────────────────────────

  Widget _buildArticlesStream(List<KnowledgeArticle> articles, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ARTICLES & MONOGRAPHS (${articles.length})",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        if (articles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                "No articles match your search or filter criteria.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final art = articles[index];
              return InkWell(
                onTap: () => _openArticle(art),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  art.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: JeevanSutraColors.mutedGold,
                                  ),
                                ),
                                const Text(" • ", style: TextStyle(color: JeevanSutraColors.secondaryText, fontSize: 10)),
                                Text(
                                  "${art.readingTimeMinutes} min",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              art.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              art.excerpt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: art.tags.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "#$tag",
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          art.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: art.isBookmarked
                              ? (isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen)
                              : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            art.isBookmarked = !art.isBookmarked;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─── Botanical Adaptogens Section ──────────────────────────────────────────

  Widget _buildBotanicalAdaptogens(List<MedicinalPlant> plants, bool isDark) {
    if (plants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "BOTANICAL ADAPTOGENS (${plants.length})",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicinalPlantsScreen())),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text(
                "Herbarium",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: plants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = plants[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlantDetailScreen.fromMedicinalPlant(p),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 180,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.eco_rounded,
                              size: 16,
                              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                            ),
                          ),
                          Text(
                            (p.balancingDosha.isNotEmpty ? p.balancingDosha.first.name.toUpperCase() : 'TRIDOSHIC'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.commonName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                            ),
                          ),
                          Text(
                            p.botanicalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
