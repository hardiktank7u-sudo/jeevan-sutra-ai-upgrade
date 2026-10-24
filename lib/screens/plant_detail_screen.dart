import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../models/wellness_models.dart' show MedicinalPlant;
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({
    super.key,
    required this.plant,
  });

  /// Convenience constructor from a [MedicinalPlant] (wellness_models).
  factory PlantDetailScreen.fromMedicinalPlant(MedicinalPlant mp, {Key? key}) {
    final plant = Plant(
      id: mp.id,
      commonName: mp.commonName,
      sanskritName: mp.sanskritName,
      scientificName: mp.botanicalName,
      family: mp.category,
      category: mp.category,
      identification: mp.primaryUses,
      traditionalUses: [mp.traditionalApplication],
      scientificEvidence: [mp.scientificEvidence],
      safetySummary: mp.precautions,
      precautions: [mp.precautions],
      knownCompounds: ['${mp.rasa} (rasa) • ${mp.virya} (virya) • ${mp.vipaka} (vipaka)'],
    );
    return PlantDetailScreen(key: key, plant: plant);
  }

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _storage = LocalStorageService.instance;

  late final TabController _tabController;
  bool _saved = false;
  bool _loadingSavedState = true;

  Plant get plant => widget.plant;

  final List<String> _tabs = const [
    'Overview',
    'Benefits',
    'Uses',
    'Precautions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSavedState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final savedPlants = await _storage.getSavedPlants();

    if (!mounted) return;

    setState(() {
      _saved = savedPlants.contains(plant.commonName);
      _loadingSavedState = false;
    });
  }

  Future<void> _toggleSaved() async {
    await _storage.toggleSavedPlant(plant.commonName);

    if (!mounted) return;

    setState(() {
      _saved = !_saved;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1300),
          behavior: SnackBarBehavior.floating,
          content: Text(
            _saved
                ? '${plant.commonName} saved to My Herbs'
                : '${plant.commonName} removed from My Herbs',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BotanicalBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                          child: _buildHeroCard(),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarHeaderDelegate(
                          tabBar: _buildCustomTabBar(),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildBenefitsTab(),
                      _buildUsesTab(),
                      _buildPrecautionsTab(),
                    ],
                  ),
                ),
              ),
              _buildBottomCta(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          Text(
            plant.commonName,
            style: TextStyle(
              color: context.detailText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          _CircleIconButton(
            icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            iconColor: _saved ? AppTheme.gold : context.detailSecondaryText,
            onTap: _loadingSavedState ? null : _toggleSaved,
          ),
        ],
      ),
    );
  }

  // ─── Hero Card ───────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E281C),
            Color(0xFF183D2A),
            Color(0xFF24573C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderGold),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald.withValues(alpha: 0.15),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 10,
            child: Icon(
              Icons.spa_rounded,
              size: 110,
              color: AppTheme.gold.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _plantIcon,
                        size: 30,
                        color: const Color(0xFF141004),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              plant.category.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plant.commonName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            plant.scientificName,
                            style: const TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (plant.sanskritName != null || plant.hindiName != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (plant.sanskritName != null)
                        _HeroTagPill(
                          label: 'Sanskrit: ${plant.sanskritName}',
                        ),
                      if (plant.hindiName != null)
                        _HeroTagPill(
                          label: 'Hindi: ${plant.hindiName}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Custom Tab Bar ──────────────────────────────────────────────────────

  Widget _buildCustomTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderGold),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF141004),
          unselectedLabelColor: context.detailSecondaryText,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
    );
  }

  // ─── Tab 1: Overview ─────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _DarkCard(
          title: 'Plant Profile',
          icon: Icons.local_florist_rounded,
          child: Column(
            children: [
              _DarkInfoRow(label: 'Scientific Name', value: plant.scientificName, italic: true),
              if (plant.family.isNotEmpty)
                _DarkInfoRow(label: 'Botanical Family', value: plant.family),
              if (plant.category.isNotEmpty)
                _DarkInfoRow(label: 'Ayurvedic Class', value: plant.category),
              if (plant.partsUsed.isNotEmpty)
                _DarkListPills(title: 'Parts Traditionally Used', items: plant.partsUsed),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (plant.identification.isNotEmpty) ...[
          _DarkCard(
            title: 'Botanical Identification',
            icon: Icons.visibility_rounded,
            child: Text(
              plant.identification,
              style: TextStyle(
                color: context.detailSecondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _DarkCard(
          title: 'Evidence Verification',
          icon: Icons.verified_outlined,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _formatStatus(plant.evidenceLevel),
                  style: const TextStyle(
                    color: AppTheme.emeraldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Status: ${_formatStatus(plant.reviewStatus)}',
                style: TextStyle(
                  color: context.detailSecondaryText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDisclaimerBanner(),
      ],
    );
  }

  // ─── Tab 2: Benefits ─────────────────────────────────────────────────────

  Widget _buildBenefitsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _DarkCard(
          title: 'Researched Benefits & Evidence',
          icon: Icons.science_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plant.scientificEvidence.isEmpty)
                Text(
                  'Scientific research data is being verified for this record.',
                  style: TextStyle(color: context.detailSecondaryText, fontSize: 13),
                )
              else
                ...plant.scientificEvidence.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 6, color: AppTheme.gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: context.detailSecondaryText,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (plant.knownCompounds.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DarkCard(
            title: 'Key Active Phytochemicals',
            icon: Icons.biotech_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plant.knownCompounds.map((compound) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.detailInsetSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderGoldSubtle),
                  ),
                  child: Text(
                    compound,
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Tab 3: Uses ─────────────────────────────────────────────────────────

  Widget _buildUsesTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _DarkCard(
          title: 'Traditional Ayurvedic Uses',
          icon: Icons.history_edu_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plant.traditionalUses.isEmpty)
                Text(
                  'Traditional applications are being curated from classical texts.',
                  style: TextStyle(color: context.detailSecondaryText, fontSize: 13),
                )
              else
                ...plant.traditionalUses.map(
                  (use) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.detailInsetSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderGoldSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.spa_rounded, color: AppTheme.gold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              use,
                              style: TextStyle(
                                color: context.detailText,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (plant.traditionalReferences.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DarkCard(
            title: 'Classical Texts & References',
            icon: Icons.menu_book_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plant.traditionalReferences.map((ref) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bookmark_border_rounded,
                          color: AppTheme.goldLight, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ref,
                          style: TextStyle(
                            color: context.detailSecondaryText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Tab 4: Precautions ──────────────────────────────────────────────────

  Widget _buildPrecautionsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        if (plant.isToxic || plant.toxicityWarning != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1515),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE57373), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plant.toxicityWarning ??
                        'Caution: This botanical specimen contains potent compounds. Do not ingest without medical supervision.',
                    style: const TextStyle(
                      color: Color(0xFFFFCDD2),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _DarkCard(
          title: 'Safety Guidelines & Precautions',
          icon: Icons.shield_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plant.safetySummary.isNotEmpty) ...[
                Text(
                  plant.safetySummary,
                  style: TextStyle(
                    color: context.detailSecondaryText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (plant.precautions.isNotEmpty)
                ...plant.precautions.map(
                  (precaution) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: AppTheme.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            precaution,
                            style: TextStyle(
                              color: context.detailSecondaryText,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'No adverse interaction precautions currently recorded.',
                  style: TextStyle(color: context.detailSecondaryText, fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottom CTA: Add to My Herbs ─────────────────────────────────────────

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _saved ? null : AppTheme.goldGradient,
            color: _saved ? Theme.of(context).cardColor : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _saved ? AppTheme.borderGold : Colors.transparent,
            ),
            boxShadow: _saved
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _loadingSavedState ? null : _toggleSaved,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              _saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
              color: _saved ? AppTheme.gold : const Color(0xFF141004),
              size: 22,
            ),
            label: Text(
              _saved ? 'Added to My Herbs' : 'Add to My Herbs',
              style: TextStyle(
                color: _saved ? AppTheme.goldLight : const Color(0xFF141004),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGoldSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Jeevan Sutra provides educational Indian Knowledge information and does not replace medical advice or prescription.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: context.detailSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _plantIcon {
    switch (plant.id) {
      case 'tulsi':
        return Icons.eco_rounded;
      case 'neem':
        return Icons.spa_rounded;
      case 'aloe_vera':
        return Icons.grass_rounded;
      case 'ashwagandha':
        return Icons.local_florist_rounded;
      case 'turmeric':
        return Icons.grass_rounded;
      case 'dhatura':
        return Icons.warning_amber_rounded;
      default:
        return Icons.local_florist_rounded;
    }
  }

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return 'General';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent Header Delegate for Pinned TabBar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _TabBarHeaderDelegate({required this.tabBar});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI Components
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderGold),
          ),
          child: Icon(icon, color: iconColor ?? context.detailText, size: 20),
        ),
      ),
    );
  }
}

class _HeroTagPill extends StatelessWidget {
  final String label;

  const _HeroTagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DarkCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderGold),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGold),
                ),
                child: Icon(icon, color: AppTheme.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.detailText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DarkInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool italic;

  const _DarkInfoRow({
    required this.label,
    required this.value,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.detailSecondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: context.detailText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkListPills extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DarkListPills({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.detailSecondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((part) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.detailInsetSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGoldSubtle),
              ),
              child: Text(
                part,
                style: const TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Resolve legacy detail colors through the active botanical theme.
extension _PlantDetailColors on BuildContext {
  Color get detailText => Theme.of(this).colorScheme.onSurface;

  Color get detailSecondaryText =>
      Theme.of(this).brightness == Brightness.dark
          ? JeevanSutraColors.darkTextSecondary
          : JeevanSutraColors.secondaryText;

  Color get detailInsetSurface =>
      Theme.of(this).brightness == Brightness.dark
          ? JeevanSutraColors.darkSurfaceElevated
          : JeevanSutraColors.softSage;
}
