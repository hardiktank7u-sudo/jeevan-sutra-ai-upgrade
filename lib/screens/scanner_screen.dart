// Google AI Studio - Jeevan Sutra Plant Scanner Screen
// High-tech botanical viewfinder, spectral diagnostics & Gemini plant taxonomy
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/sample_data.dart';
import '../models/plant.dart';
import '../models/wellness_models.dart';
import '../services/gemini_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';
import 'plant_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImage;
  String? _selectedFileName;
  bool _isScanning = false;
  bool _flashActive = false;
  PlantScanResult? _scanResult;
  MedicinalPlant? _samplePlant;
  int _sampleIndex = 0;

  List<Map<String, dynamic>> _history = [];
  late final AnimationController _laserController;

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
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = bytes;
        _selectedFileName = file.name;
        _scanResult = null;
        _isScanning = true;
      });

      await LocalStorageService.instance.addScanHistory(fileName: file.name);
      await _loadHistory();

      // Scan with Gemini AI
      try {
        final result = await GeminiService.instance.analyzePlantImage(bytes);
        if (!mounted) return;
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });
      } catch (e) {
        // Fallback to sample botanical data
        if (!mounted) return;
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI diagnosis note: $e")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not access camera/gallery: $e")),
      );
    }
  }

  void _simulateSampleScan() {
    setState(() {
      _selectedImage = null;
      _isScanning = true;
      _scanResult = null;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final current = SampleData.medicinalPlants[_sampleIndex];
      setState(() {
        _isScanning = false;
        _scanResult = PlantScanResult(plantName: current.commonName, scientificName: current.botanicalName, confidence: 0.984, identification: current.primaryUses, traditionalUses: current.traditionalApplication, scientificEvidence: current.scientificEvidence, safetySummary: current.precautions, precautions: [current.precautions]);
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
                _buildViewfinder(isDark),
                const SizedBox(height: 16),
                _buildActionButtons(isDark),
                const SizedBox(height: 20),
                if (_isScanning) _buildScanningIndicator(isDark),
                if (_scanResult != null) _buildScanResultCard(_scanResult!, isDark),
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
              color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              "BOTANICAL DIAGNOSTICS",
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
          "Plant Scanner & Identifier",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Optical identification and taxonomy for medicinal flora & herbs.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
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
                InkWell(
                  onTap: () => setState(() => _flashActive = !_flashActive),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _flashActive ? Colors.amber : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: _flashActive ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "SCAN_MODE: 4K_SPECTRAL",
                    style: TextStyle(
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
                    child: const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
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
                          top: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
                          left: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
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
                          top: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
                          right: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
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
                          bottom: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
                          left: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
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
                          bottom: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
                          right: BorderSide(color: JeevanSutraColors.freshLeaf, width: 2.5),
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
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 54,
                                color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.8),
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
                                colors: [Colors.transparent, JeevanSutraColors.freshLeaf, Colors.transparent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.8),
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
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
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
                          color: JeevanSutraColors.forestGreen.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.science_rounded, color: JeevanSutraColors.freshLeaf, size: 24),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.photo_camera_rounded, size: 18),
            label: const Text("Capture Herb", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
              side: BorderSide(color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.image_rounded, size: 18),
            label: const Text("Upload Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JeevanSutraColors.freshLeaf),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: JeevanSutraColors.forestGreen),
          ),
          SizedBox(width: 12),
          Text(
            "Analyzing botanical taxonomy and Ayurvedic properties...",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: JeevanSutraColors.forestGreen),
          ),
        ],
      ),
    );
  }

  // ─── Scan Result Monograph Card ────────────────────────────────────────────

  Widget _buildScanResultCard(PlantScanResult result, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JeevanSutraColors.freshLeaf.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "CONFIDENCE: ${(result.confidence * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: JeevanSutraColors.forestGreen,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_rounded, color: JeevanSutraColors.mutedGold),
                tooltip: "Save to Sanctuary Herbarium",
                onPressed: () async {
                  await LocalStorageService.instance.savePlant(result.plantName);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${result.plantName} saved to Sanctuary Herbarium!")),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.plantName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
            ),
          ),
          Text(
            result.scientificName ?? result.plantName,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
            ),
          ),
          const Divider(height: 24),
          _buildResultRow("Ayurvedic Properties", result.identification, isDark),
          const SizedBox(height: 10),
          _buildResultRow("Primary Indications", result.traditionalUses, isDark),
          const SizedBox(height: 10),
          _buildResultRow("Safety & Caution", result.safetySummary, isDark),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantDetailScreen(plant: result.matchedLocalPlant ?? Plant(id: 'scan_result', commonName: result.plantName, scientificName: result.scientificName ?? result.plantName, identification: result.identification, traditionalUses: [result.traditionalUses], scientificEvidence: [result.scientificEvidence], safetySummary: result.safetySummary, precautions: result.precautions)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: JeevanSutraColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Text("View Full Monograph", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ),
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
            color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
          ),
        ),
      ],
    );
  }

  // ─── Scan History List ─────────────────────────────────────────────────────

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
            color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.take(4).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _history[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, size: 18, color: JeevanSutraColors.freshLeaf),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['fileName']?.toString() ?? 'Botanical Specimen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                      ),
                    ),
                  ),
                  Text(
                    item['timestamp']?.toString().split('T').first ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
