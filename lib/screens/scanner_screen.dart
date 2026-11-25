// Jeevan Sutra plant camera and catalogue-guided identification screen
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/sample_data.dart';
import '../models/plant.dart';
import '../models/wellness_models.dart';
import '../repositories/content_repository.dart';
import '../services/gemini_service.dart';
import '../services/local_storage_service.dart';
import '../services/plant_feature_matcher.dart';
import '../services/visible_image_summary.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import 'plant_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.imagePicker, this.plantAnalyzer});

  final Future<XFile?> Function(ImageSource source)? imagePicker;
  final Future<PlantScanResult> Function(Uint8List bytes)? plantAnalyzer;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImage;
  bool _isScanning = false;
  PlantScanResult? _scanResult;
  MedicinalPlant? _samplePlant;
  int _sampleIndex = 0;
  int _scanGeneration = 0;
  bool _isPickingImage = false;
  Timer? _sampleScanTimer;

  List<Map<String, dynamic>> _history = [];
  late final AnimationController _laserController;
  bool _guidedMode = false;
  VisibleImageSummary? _imageSummary;
  PlantCatalogueLoad? _catalogue;
  List<PlantTraitProfile> _profiles = const [];
  final Set<String> _selectedTraitIds = <String>{};
  List<PlantFeatureMatch> _rankedMatches = const [];
  bool _matchesRanked = false;
  String? _guidedError;
  String? _guidedFileName;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _samplePlant = SampleData.medicinalPlants.first;
    _loadHistory();
  }

  @override
  void dispose() {
    _scanGeneration++;
    _sampleScanTimer?.cancel();
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await LocalStorageService.instance.getScanHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    var picking = true;
    try {
      final XFile? file = widget.imagePicker != null
          ? await widget.imagePicker!(source)
          : await _picker.pickImage(
              source: source,
              imageQuality: 88,
              maxWidth: 1600,
              maxHeight: 1600,
            );

      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      picking = false;
      _isPickingImage = false;
      if (!mounted) return;
      final generation = ++_scanGeneration;
      _sampleScanTimer?.cancel();

      if (source == ImageSource.gallery && widget.plantAnalyzer == null) {
        await _beginGuidedComparison(
          fileName: file.name,
          bytes: bytes,
          generation: generation,
        );
        return;
      }

      await _analyzeImageWithGemini(
        fileName: file.name,
        bytes: bytes,
        generation: generation,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not access camera/gallery: $e")),
      );
    } finally {
      if (picking) _isPickingImage = false;
    }
  }

  Future<void> _analyzeImageWithGemini({
    required String fileName,
    required Uint8List bytes,
    required int generation,
  }) async {
    setState(() {
      _guidedMode = false;
      _selectedImage = bytes;
      _scanResult = null;
      _isScanning = true;
    });

    try {
      await LocalStorageService.instance.addScanHistory(fileName: fileName);
      await _loadHistory();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The scan could not be saved on this device.'),
          ),
        );
      }
    }
    if (!mounted || generation != _scanGeneration) return;

    // Scan with Gemini AI
    try {
      final analyze =
          widget.plantAnalyzer ?? GeminiService.instance.analyzePlantImage;
      final result = await analyze(bytes);
      if (!mounted || generation != _scanGeneration) return;
      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
      try {
        await LocalStorageService.instance.addScanHistory(
          fileName: fileName,
          plantName: result.plantName,
          confidence: result.confidence,
          scanResult: _scanResultToStorage(result),
        );
        await _loadHistory();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The scan result could not be saved on this device.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted || generation != _scanGeneration) return;
      final failureMessage =
          'Automatic image recognition was unavailable. ${GeminiService.describeFailure(e)} Guided matching is ready.';
      await _beginGuidedComparison(
        fileName: fileName,
        bytes: bytes,
        generation: generation,
        saveHistory: false,
        initialError: failureMessage,
      );
    }
  }

  Future<void> _beginGuidedComparison({
    required String fileName,
    required Uint8List bytes,
    required int generation,
    bool saveHistory = true,
    String? initialError,
  }) async {
    setState(() {
      _guidedMode = true;
      _guidedFileName = fileName;
      _selectedImage = bytes;
      _scanResult = null;
      _isScanning = true;
      _imageSummary = null;
      _catalogue = null;
      _profiles = const [];
      _rankedMatches = const [];
      _matchesRanked = false;
      _guidedError = initialError;
      _selectedTraitIds.clear();
    });

    if (saveHistory) {
      try {
        await LocalStorageService.instance.addScanHistory(fileName: fileName);
        await _loadHistory();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The photo could not be saved on this device.'),
            ),
          );
        }
      }
    }
    if (!mounted || generation != _scanGeneration) return;

    final summary = await VisibleImageSummary.fromBytes(bytes);
    if (!mounted || generation != _scanGeneration) return;

    try {
      final catalogue = await ContentRepository.loadComparisonCatalogue();
      if (!mounted || generation != _scanGeneration) return;
      setState(() {
        _imageSummary = summary;
        _catalogue = catalogue;
        _profiles = PlantFeatureMatcher.index(catalogue.plants);
        _isScanning = false;
        if (initialError != null) {
          _guidedError = initialError;
        }
      });
    } catch (_) {
      if (!mounted || generation != _scanGeneration) return;
      setState(() {
        _imageSummary = summary;
        _isScanning = false;
        _guidedError = 'The plant catalogue could not be read on this device.';
      });
    }
  }

  Future<void> _rankGuidedMatches() async {
    if (_selectedTraitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one trait you can see or smell. Traits are not detected automatically.',
          ),
        ),
      );
      return;
    }
    final ranked = PlantFeatureMatcher.rank(
      profiles: _profiles,
      selectedTraitIds: _selectedTraitIds,
    );
    setState(() {
      _rankedMatches = ranked;
      _matchesRanked = true;
    });
    final top = ranked.isEmpty ? null : ranked.first;
    final fileName = _guidedFileName;
    if (top == null || fileName == null) return;
    try {
      await LocalStorageService.instance.addScanHistory(
        fileName: fileName,
        plantName: 'Guided trait match: ${top.plant.commonName}',
        confidence: top.similarity,
        scanResult: {
          'plantName': 'Guided trait match: ${top.plant.commonName}',
          'scientificName': top.plant.scientificName,
          'family': top.plant.family,
          'organismType': 'guided-match',
          'confidence': top.similarity,
          'liveAiAvailable': false,
          'identification':
              'Trait overlap only. ${top.matchedTraits.length} of ${top.selectedCount} selected traits are written in this record. This is not automatic visual recognition.',
          'traditionalUses': top.plant.traditionalUses.join('\n'),
          'scientificEvidence': top.plant.scientificEvidence.join('\n'),
          'safetySummary': top.plant.safetySummary,
          'isToxic': top.plant.isToxic,
          'toxicityWarning': top.plant.toxicityWarning,
        },
      );
      await _loadHistory();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The match could not be saved on this device.'),
          ),
        );
      }
    }
  }

  void _simulateSampleScan() {
    final generation = ++_scanGeneration;
    final current = SampleData.medicinalPlants[_sampleIndex];
    _sampleScanTimer?.cancel();
    setState(() {
      _guidedMode = false;
      _selectedImage = null;
      _isScanning = true;
      _scanResult = null;
    });

    _sampleScanTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || generation != _scanGeneration) return;
      setState(() {
        _isScanning = false;
        _scanResult = PlantScanResult(
          plantName: current.commonName,
          scientificName: current.botanicalName,
          confidence: 0.984,
          isSampleDemonstration: true,
          identification: current.primaryUses,
          traditionalUses: current.traditionalApplication,
          scientificEvidence: current.scientificEvidence,
          safetySummary: current.precautions,
          precautions: [current.precautions],
        );
      });
    });
  }

  void _cycleNextSample() {
    setState(() {
      _sampleIndex = (_sampleIndex + 1) % SampleData.medicinalPlants.length;
      _samplePlant = SampleData.medicinalPlants[_sampleIndex];
    });
    _simulateSampleScan();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                _buildViewfinder(isDark),
                const SizedBox(height: 16),
                _buildActionButtons(isDark),
                const SizedBox(height: 20),
                if (_isScanning)
                  _buildScanningIndicator(
                    isDark,
                    message: _guidedMode
                        ? 'Reading photo colors and loading the plant catalogue...'
                        : 'Analyzing botanical taxonomy and Ayurvedic properties...',
                  ),
                if (_guidedMode) _buildGuidedMatcher(isDark),
                if (_scanResult != null && !_guidedMode)
                  _buildScanResultCard(_scanResult!, isDark),
                const SizedBox(height: 20),
                _buildScanHistory(isDark),
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
              Icons.camera_alt_rounded,
              size: 14,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "BOTANICAL DIAGNOSTICS",
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
          "Plant Scanner & Identifier",
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
          "Choose a photo, then match visible traits against the plant catalogue. No visual recognition model is bundled.",
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

  // ─── Viewfinder Box ────────────────────────────────────────────────────────

  Widget _buildViewfinder(bool isDark) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C1914), Color(0xFF10382E), Color(0xFF0C1914)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: JeevanSutraColors.forestGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Viewfinder Header Bar
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: 'Use the camera app to control flash',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.plantAnalyzer == null
                        ? "GEMINI VISION • LIVE BOTANICAL AI"
                        : "MODEL TEST PATH • UNVERIFIED",
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: JeevanSutraColors.freshLeaf,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _cycleNextSample,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center Reticle with 4 Corner Targeting Brackets
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                children: [
                  // 4 Corner Brackets
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                          left: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                          right: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                          left: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                          right: BorderSide(
                            color: JeevanSutraColors.freshLeaf,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center Image or Plant Motif
                  Center(
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _selectedImage!,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Text(
                                      'Preview unavailable',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 54,
                                color: JeevanSutraColors.freshLeaf.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _samplePlant?.commonName ?? "Specimen Focus",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Animated Laser Scan Line
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: 180 * _laserController.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  JeevanSutraColors.freshLeaf,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: JeevanSutraColors.freshLeaf.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Shutter & Controls
          Positioned(
            bottom: 14,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: "Choose from Gallery",
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: JeevanSutraColors.forestGreen,
                      boxShadow: [
                        BoxShadow(
                          color: JeevanSutraColors.forestGreen.withValues(
                            alpha: 0.5,
                          ),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.science_rounded,
                    color: JeevanSutraColors.freshLeaf,
                    size: 24,
                  ),
                  tooltip: "Simulate Sample Scan",
                  onPressed: _simulateSampleScan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: JeevanSutraColors.forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.photo_camera_rounded, size: 18),
            label: const Text(
              "Capture Herb",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? JeevanSutraColors.darkTextPrimary
                  : JeevanSutraColors.forestGreen,
              side: BorderSide(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.subtleBorder,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.image_rounded, size: 18),
            label: const Text(
              "Upload Photo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator(bool isDark, {required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JeevanSutraColors.freshLeaf),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: JeevanSutraColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidedMatcher(bool isDark) {
    final groupedTraits = <String, List<ObservableTrait>>{};
    for (final trait in PlantFeatureMatcher.traits) {
      groupedTraits.putIfAbsent(trait.group, () => []).add(trait);
    }

    final surface = isDark
        ? JeevanSutraColors.darkSurface
        : JeevanSutraColors.pureWhite;
    final textColor = isDark
        ? JeevanSutraColors.darkTextPrimary
        : JeevanSutraColors.mainText;
    final secondaryColor = isDark
        ? JeevanSutraColors.darkTextSecondary
        : JeevanSutraColors.secondaryText;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
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
            'GUIDED IDENTIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: isDark
                  ? JeevanSutraColors.freshLeaf
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The photo is not classified by a vision model. The image summary below reports color measurements only. Select the traits you can observe; they will be compared with wording in each plant record.',
            style: TextStyle(fontSize: 12, height: 1.45, color: textColor),
          ),
          if (_imageSummary != null) ...[
            const SizedBox(height: 10),
            Text(
              _imageSummary!.explanation,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: secondaryColor,
              ),
            ),
          ],
          if (_catalogue != null) ...[
            const SizedBox(height: 10),
            Text(
              _catalogue!.comparisonNote,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: secondaryColor,
              ),
            ),
          ],
          if (_guidedError != null) ...[
            const SizedBox(height: 10),
            Text(
              _guidedError!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Select observable traits (${_selectedTraitIds.length} selected)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          for (final group in groupedTraits.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                group.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                for (final trait in group.value)
                  FilterChip(
                    label: Text(trait.label),
                    selected: _selectedTraitIds.contains(trait.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTraitIds.add(trait.id);
                        } else {
                          _selectedTraitIds.remove(trait.id);
                        }
                        _rankedMatches = const [];
                        _matchesRanked = false;
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning || _profiles.isEmpty
                  ? null
                  : _rankGuidedMatches,
              icon: const Icon(Icons.manage_search_rounded),
              label: Text('Compare against ${_profiles.length} records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JeevanSutraColors.forestGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_matchesRanked) ...[
            const SizedBox(height: 8),
            Text(
              'Similarity is a text-overlap score: matched selected traits divided by selected traits. It is not image similarity, a probability, or a confirmed identification.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            if (_rankedMatches.isEmpty)
              Text(
                'No record mentions the selected traits in its identification description.',
                style: TextStyle(fontSize: 12, color: textColor),
              )
            else ...[
              Text(
                'Best matching catalogue records',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              for (final match in _rankedMatches.take(10))
                Card(
                  color: isDark
                      ? JeevanSutraColors.darkSurfaceElevated
                      : JeevanSutraColors.warmIvory,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(
                      match.plant.commonName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      '${match.plant.scientificName}\n'
                      '${match.matchedTraits.length} of ${match.selectedCount} selected traits appear in this record',
                      style: TextStyle(fontSize: 11, color: secondaryColor),
                    ),
                    trailing: Text(
                      '${(match.similarity * 100).toStringAsFixed(0)}%\ntext overlap',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? JeevanSutraColors.freshLeaf
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(plant: match.plant),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Scan Result Monograph Card ────────────────────────────────────────────

  Map<String, dynamic> _scanResultToStorage(PlantScanResult result) => {
    'plantName': result.plantName,
    'sanskritName': result.sanskritName,
    'hindiName': result.hindiName,
    'scientificName': result.scientificName,
    'family': result.family,
    'plantCategory': result.plantCategory,
    'medicinalClassification': result.medicinalClassification,
    'growingInformation': result.growingInformation,
    'organismType': result.organismType,
    'confidence': result.confidence,
    'liveAiAvailable': result.liveAiAvailable,
    'identification': result.identification,
    'traditionalUses': result.traditionalUses,
    'scientificEvidence': result.scientificEvidence,
    'safetySummary': result.safetySummary,
    'precautions': result.precautions,
    'isToxic': result.isToxic,
    'toxicityWarning': result.toxicityWarning,
    'reviewStatus': 'ai_scan_unverified',
  };

  Plant _plantFromScanResult(PlantScanResult result) {
    final matchedPlant = result.matchedLocalPlant;
    if (matchedPlant == null) {
      return Plant(
        id: 'scan_result',
        commonName: result.plantName,
        sanskritName: result.sanskritName,
        hindiName: result.hindiName,
        scientificName: result.scientificName ?? result.plantName,
        family: result.family ?? '',
        category: result.plantCategory ?? 'AI identified (unverified)',
        medicinalClassification: result.medicinalClassification,
        growingInformation: result.growingInformation,
        identification: result.identification,
        traditionalUses: [result.traditionalUses],
        scientificEvidence: [result.scientificEvidence],
        safetySummary: result.safetySummary,
        precautions: result.precautions,
        isToxic: result.isToxic,
        toxicityWarning: result.toxicityWarning,
        organismType: result.organismType,
        confidence: result.confidence,
        reviewStatus: 'ai_scan_unverified',
      );
    }
    final mergedIsToxic = result.isToxic == true || matchedPlant.isToxic == true
        ? true
        : result.isToxic == false || matchedPlant.isToxic == false
        ? false
        : null;
    return Plant.fromJson({
      ...matchedPlant.toJson(),
      'isToxic': mergedIsToxic,
      'toxicityWarning': result.toxicityWarning ?? matchedPlant.toxicityWarning,
      'organismType': result.organismType,
      'confidence': result.confidence,
      'category': result.plantCategory ?? matchedPlant.category,
      'medicinalClassification': result.medicinalClassification,
      'growingInformation': result.growingInformation,
      'identification': result.identification,
      'traditionalUses': [result.traditionalUses],
      'scientificEvidence': [result.scientificEvidence],
      'safetySummary': result.safetySummary,
      'precautions': result.precautions,
      'reviewStatus': 'ai_scan_unverified',
    });
  }

  Widget _buildScanResultCard(PlantScanResult result, bool isDark) {
    final isSampleDemonstration = result.isSampleDemonstration;
    final isUncertain =
        result.organismType == 'uncertain' || result.confidence < 0.6;
    final isConfirmedPlant = result.organismType == 'plant' && !isUncertain;
    final canOpenMonograph = isConfirmedPlant && !isSampleDemonstration;
    final statusLabel = isSampleDemonstration
        ? 'SAMPLE DEMONSTRATION • NOT A SCAN'
        : isUncertain
        ? 'UNCERTAIN — NOT CONFIRMED'
        : switch (result.organismType) {
            'fungus' => 'FUNGUS — NOT A PLANT',
            'non-plant' => 'NO PLANT DETECTED',
            _ =>
              'MODEL-REPORTED CONFIDENCE: ${(result.confidence * 100).toStringAsFixed(1)}%',
          };
    return Container(
      padding: const EdgeInsets.all(20),
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
              if (canOpenMonograph)
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_add_rounded,
                    color: JeevanSutraColors.mutedGold,
                  ),
                  tooltip: "Save to Sanctuary Herbarium",
                  onPressed: () async {
                    await LocalStorageService.instance.savePlantRecord(
                      _plantFromScanResult(result),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${result.plantName} saved to Sanctuary Herbarium!",
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSampleDemonstration
                ? 'Sample: ${result.plantName}'
                : isUncertain
                ? 'Uncertain identification'
                : result.plantName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? JeevanSutraColors.darkTextPrimary
                  : JeevanSutraColors.forestGreen,
            ),
          ),
          Text(
            isUncertain
                ? result.plantName == 'Unidentified Botanical'
                      ? 'No reliable match'
                      : 'Possible match: ${result.plantName}'
                : isConfirmedPlant
                ? result.scientificName ?? result.plantName
                : result.organismType == 'fungus'
                ? 'Fungus — not a plant'
                : 'No plant identified',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),
          if (isConfirmedPlant &&
              result.family != null &&
              result.family!.isNotEmpty)
            Text(
              'Family: ${result.family}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
          if (isConfirmedPlant &&
              result.plantCategory != null &&
              result.plantCategory!.isNotEmpty)
            Text(
              'Category: ${result.plantCategory}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? JeevanSutraColors.darkTextSecondary
                    : JeevanSutraColors.secondaryText,
              ),
            ),
          Text(
            'Classification: ${isUncertain ? 'uncertain' : result.organismType}',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSampleDemonstration
                ? 'Demonstration content only. This result was not derived from an image.'
                : 'AI-generated identification is unverified. Confidence is a model estimate, not a guarantee of accuracy.',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),
          if (!result.liveAiAvailable) ...[
            const SizedBox(height: 8),
            _buildResultRow(
              'Live AI unavailable',
              'This image was not identified by Gemini. Check your connection and try again.',
              isDark,
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _beginGuidedComparison(
                    fileName: _guidedFileName ?? 'specimen.jpg',
                    bytes: _selectedImage!,
                    generation: ++_scanGeneration,
                    saveHistory: false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.forestGreen,
                  side: BorderSide(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Compare with 92 Bundled Records'),
              ),
            ],
          ],
          const Divider(height: 24),
          _buildResultRow(
            "Visual Identification",
            result.identification,
            isDark,
          ),
          if (isConfirmedPlant && result.medicinalClassification != null) ...[
            const SizedBox(height: 10),
            _buildResultRow(
              'Medicinal classification (AI-reported)',
              result.medicinalClassification!,
              isDark,
            ),
          ],
          const SizedBox(height: 10),
          _buildResultRow(
            "Traditional Uses (AI-reported; unverified)",
            result.traditionalUses,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildResultRow(
            "Scientific Evidence (AI-reported; unverified)",
            result.scientificEvidence,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildResultRow("Safety & Caution", result.safetySummary, isDark),
          if (result.toxicityWarning != null) ...[
            const SizedBox(height: 10),
            _buildResultRow(
              result.isToxic == true ? "Toxicity Warning" : "Toxicity Status",
              result.toxicityWarning!,
              isDark,
            ),
          ],
          if (result.precautions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildResultRow(
              "Precautions (AI-reported; unverified)",
              result.precautions.join('\n'),
              isDark,
            ),
          ],
          if (isConfirmedPlant &&
              result.growingInformation != null &&
              result.growingInformation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildResultRow(
              'Growing information (AI-reported)',
              result.growingInformation!,
              isDark,
            ),
          ],
          if (canOpenMonograph) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        final plant = _plantFromScanResult(result);
                        return PlantDetailScreen(plant: plant);
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: JeevanSutraColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Text(
                  "View Full Monograph",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark
                ? JeevanSutraColors.freshLeaf
                : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: isDark
                ? JeevanSutraColors.darkTextPrimary
                : JeevanSutraColors.mainText,
          ),
        ),
      ],
    );
  }

  // ─── Scan History List ─────────────────────────────────────────────────────

  void _openHistoryEntry(Map<String, dynamic> item) {
    final organismType = item['organismType']?.toString();
    final confidence = (item['confidence'] as num?)?.toDouble();
    final isConfirmedPlant =
        organismType == 'plant' && confidence != null && confidence >= 0.6;

    if (isConfirmedPlant) {
      final isToxic = item['isToxic'] is bool ? item['isToxic'] as bool : null;
      final plant = Plant(
        id: 'saved_scan_${item['timestamp'] ?? item['time'] ?? item['fileName']}',
        commonName:
            item['plantName']?.toString() ??
            item['name']?.toString() ??
            'Botanical specimen',
        sanskritName: item['sanskritName']?.toString(),
        hindiName: item['hindiName']?.toString(),
        scientificName:
            item['scientificName']?.toString() ??
            item['plantName']?.toString() ??
            'Unverified identification',
        family: item['family']?.toString() ?? '',
        category: item['plantCategory']?.toString() ?? 'General',
        medicinalClassification: item['medicinalClassification']?.toString(),
        growingInformation: item['growingInformation']?.toString(),
        identification: item['identification']?.toString() ?? '',
        traditionalUses: item['traditionalUses']?.toString().isNotEmpty == true
            ? [item['traditionalUses'].toString()]
            : const [],
        scientificEvidence:
            item['scientificEvidence']?.toString().isNotEmpty == true
            ? [item['scientificEvidence'].toString()]
            : const [],
        safetySummary:
            item['safetySummary']?.toString() ??
            'Do not consume or use an unidentified plant medicinally.',
        precautions: item['precautions'] is List
            ? (item['precautions'] as List).whereType<String>().toList()
            : const [],
        isToxic: isToxic,
        toxicityWarning: item['toxicityWarning']?.toString(),
        organismType: 'plant',
        confidence: confidence,
        reviewStatus: 'ai_scan_unverified',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
      );
      return;
    }

    final liveAiUnavailable = item['liveAiAvailable'] == false;
    final classification = liveAiUnavailable
        ? 'Live AI identification was unavailable'
        : switch (organismType) {
            'fungus' => 'Fungus — not a plant',
            'non-plant' => 'No plant detected',
            _ => 'Uncertain identification — not confirmed',
          };
    final warning = item['toxicityWarning']?.toString();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item['plantName']?.toString() ??
              item['name']?.toString() ??
              'Scan result',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(classification),
            const SizedBox(height: 12),
            Text(
              liveAiUnavailable
                  ? 'This scan was not identified by Gemini. Do not consume or use this organism medicinally.'
                  : 'Do not consume or use this organism medicinally. Identification and safety are unverified.',
            ),
            if (warning != null && warning.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(warning),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistory(bool isDark) {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RECENT BOTANICAL SCANS (${_history.length})",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark
                ? JeevanSutraColors.freshLeaf
                : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.take(4).length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _history[index];
            return InkWell(
              onTap: () => _openHistoryEntry(item),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? JeevanSutraColors.darkSurface
                      : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 18,
                      color: JeevanSutraColors.freshLeaf,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['plantName']?.toString() ??
                            item['fileName']?.toString() ??
                            item['name']?.toString() ??
                            'Botanical Specimen',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.mainText,
                        ),
                      ),
                    ),
                    Text(
                      item['timestamp']?.toString().split('T').first ??
                          item['time']?.toString().split('T').first ??
                          '',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
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
}
