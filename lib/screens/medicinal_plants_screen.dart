// Google AI Studio - Jeevan Sutra Medicinal Plants Screen
// Classical Dravyaguna encyclopedia & phytochemical pharmacology
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../repositories/content_repository.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import 'plant_detail_screen.dart';

class MedicinalPlantsScreen extends StatefulWidget {
  const MedicinalPlantsScreen({super.key});

  @override
  State<MedicinalPlantsScreen> createState() => _MedicinalPlantsScreenState();
}

class _MedicinalPlantsScreenState extends State<MedicinalPlantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _plants = [];
  Set<String> _savedPlants = {};
  bool _loading = true;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Adaptogen & Respiratory',
    'Neuro-Endocrine & Strength',
    'Anti-Inflammatory & Blood Purifier',
    'Nootropic & Cognitive Clarity',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    try {
      final results = await Future.wait([
        LocalStorageService.instance.getSavedPlants(),
        ContentRepository.loadPlants(),
      ]);

      if (!mounted) return;
      setState(() {
        _savedPlants = Set<String>.from(results[0] as List<String>);
        _plants = List<Plant>.from(results[1] as List<Plant>);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBookmark(Plant plant) async {
    final name = plant.commonName;
    if (_savedPlants.contains(name)) {
      await LocalStorageService.instance.removePlant(name);
      setState(() => _savedPlants.remove(name));
    } else {
      await LocalStorageService.instance.savePlant(name);
      setState(() => _savedPlants.add(name));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name saved to your botanical sanctuary."), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPlants = _plants.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.commonName.toLowerCase().contains(q) ||
          (p.sanskritName?.toLowerCase().contains(q) ?? false) ||
          p.botanicalName.toLowerCase().contains(q) ||
          (p.primaryUses?.toLowerCase().contains(q) ?? false);

      final matchesCategory = _selectedCategory == 'All' ||
          (p.category != null && p.category!.toLowerCase().contains(_selectedCategory.split(' ').first.toLowerCase()));

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Medicinal Plants"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: JeevanSutraColors.forestGreen))
              : SingleChildScrollView(
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
                      _buildPlantGrid(filteredPlants, isDark),
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
              Icons.eco_rounded,
              size: 14,
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "VEDIC FLORA ENCYCLOPEDIA",
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
          "Medicinal Plants & Dravyaguna",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Phytochemical pharmacology, traditional virya, and therapeutic applications.",
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
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 12.5,
          color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
        ),
        decoration: InputDecoration(
          hintText: "Search by common, Latin, or Sanskrit name...",
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

  // ─── Category Filter Chips ─────────────────────────────────────────────────

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

  // ─── Plants List / Grid ────────────────────────────────────────────────────

  Widget _buildPlantGrid(List<Plant> plants, bool isDark) {
    if (plants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            "No botanical specimens found matching your query.",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final plant = plants[index];
        final isSaved = _savedPlants.contains(plant.commonName);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlantDetailScreen(plant: plant),
              ),
            );
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_rounded, color: JeevanSutraColors.forestGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plant.commonName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                              ),
                            ),
                          ),
                          if (plant.doshaImpact != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plant.doshaImpact!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: JeevanSutraColors.forestGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        "${plant.sanskritName != null ? '${plant.sanskritName} • ' : ''}${plant.botanicalName}",
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                        ),
                      ),
                      if (plant.primaryUses != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          plant.primaryUses!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved
                        ? (isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen)
                        : (isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText),
                    size: 20,
                  ),
                  onPressed: () => _toggleBookmark(plant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
