// Google AI Studio - Jeevan Sutra Indian Knowledge Library Screen
// Classical Vedic treatises bridged with modern clinical & scientific research
import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/wellness_models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class KnowledgeLibraryScreen extends StatefulWidget {
  const KnowledgeLibraryScreen({super.key});

  @override
  State<KnowledgeLibraryScreen> createState() => _KnowledgeLibraryScreenState();
}

class _KnowledgeLibraryScreenState extends State<KnowledgeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'All';

  final List<String> _tabs = [
    'All',
    'Scientific Wellness',
    'Ayurveda & Traditional Wisdom',
    'Yoga & Meditation',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticleModal(KnowledgeArticle article) {
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: JeevanSutraColors.mutedGold.withValues(
                            alpha: 0.2,
                          ),
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
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  Text(
                    article.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "By ${article.author} • ${article.readingTimeMinutes} min read",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? JeevanSutraColors.freshLeaf
                          : JeevanSutraColors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    article.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.mainText,
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
                        backgroundColor: isDark
                            ? JeevanSutraColors.darkCanvas
                            : JeevanSutraColors.warmIvory,
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
      final matchesTab = _selectedTab == 'All' || art.category == _selectedTab;
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          art.title.toLowerCase().contains(q) ||
          art.subtitle.toLowerCase().contains(q) ||
          art.excerpt.toLowerCase().contains(q) ||
          art.tags.any((t) => t.toLowerCase().contains(q));
      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Knowledge Library"),
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
                _buildSearchBar(isDark),
                const SizedBox(height: 12),
                _buildTabChips(isDark),
                const SizedBox(height: 16),
                _buildArticlesList(filteredArticles, isDark),
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
              Icons.menu_book_rounded,
              size: 14,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "CLASSICAL TREATISES & SCIENCE",
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
          "Indian Knowledge Library",
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
          "Original translations from Charaka Samhita, Sushruta Samhita, and modern peer-reviewed integrative research.",
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

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 12.5,
          color: isDark
              ? JeevanSutraColors.darkTextPrimary
              : JeevanSutraColors.mainText,
        ),
        decoration: InputDecoration(
          hintText:
              "Search Vedic treatises, chronobiology, Ojas, or breathwork...",
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark
                ? JeevanSutraColors.darkTextSecondary
                : JeevanSutraColors.secondaryText,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ─── Tab Chips ─────────────────────────────────────────────────────────────

  Widget _buildTabChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.mainText),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedTab = tab);
              },
              backgroundColor: isDark
                  ? JeevanSutraColors.darkSurface
                  : JeevanSutraColors.pureWhite,
              selectedColor: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? JeevanSutraColors.darkBorder
                            : JeevanSutraColors.subtleBorder),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Articles List ─────────────────────────────────────────────────────────

  Widget _buildArticlesList(List<KnowledgeArticle> articles, bool isDark) {
    if (articles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            "No articles match your search criteria.",
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final art = articles[index];

        return InkWell(
          onTap: () => _openArticleModal(art),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? JeevanSutraColors.darkSurface
                  : JeevanSutraColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: JeevanSutraColors.mutedGold.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        art.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: JeevanSutraColors.mutedGold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: JeevanSutraColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${art.readingTimeMinutes} min",
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? JeevanSutraColors.darkTextSecondary
                                : JeevanSutraColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  art.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                Text(
                  art.subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? JeevanSutraColors.darkTextSecondary
                        : JeevanSutraColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  art.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? JeevanSutraColors.darkTextSecondary
                        : JeevanSutraColors.mainText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "By ${art.author}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: JeevanSutraColors.mutedGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        art.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: art.isBookmarked
                            ? (isDark
                                  ? JeevanSutraColors.freshLeaf
                                  : JeevanSutraColors.forestGreen)
                            : (isDark
                                  ? JeevanSutraColors.darkTextSecondary
                                  : JeevanSutraColors.secondaryText),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          art.isBookmarked = !art.isBookmarked;
                        });
                        LocalStorageService.instance.saveWisdom(art.title);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
