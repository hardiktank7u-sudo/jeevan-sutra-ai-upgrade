import 'dart:typed_data';

import '../models/plant.dart';
import 'gemini_service.dart';

class GeminiPlantService {
  GeminiPlantService({Future<PlantScanResult> Function(Uint8List)? analyzer})
    : _analyzer = analyzer ?? GeminiService.instance.analyzePlantImage;

  static final GeminiPlantService instance = GeminiPlantService();
  final Future<PlantScanResult> Function(Uint8List) _analyzer;

  Future<Plant?> identifyPlant(Uint8List imageBytes) async {
    final result = await _analyzer(imageBytes);
    if (result.organismType != 'plant' || result.confidence < 0.6) return null;

    return Plant(
      id: 'ai_scan',
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
}
