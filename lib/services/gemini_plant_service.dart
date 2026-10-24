import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/plant.dart';
import '../repositories/content_repository.dart';
import 'gemini_service.dart';

class GeminiPlantService {
  GeminiPlantService._();

  static final GeminiPlantService instance = GeminiPlantService._();

  Future<Plant?> identifyPlant(Uint8List imageBytes) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: GeminiService.modelName,
    );

    final response = await model
        .generateContent([
          Content.multi([
            TextPart(
              'Identify the medicinal plant in this image. '
              'Return ONLY the most likely common plant name. '
              'If you are not reasonably confident, return UNKNOWN.',
            ),
            InlineDataPart(GeminiService.imageMimeType(imageBytes), imageBytes),
          ]),
        ])
        .timeout(const Duration(seconds: 60));

    final name = response.text?.trim() ?? '';

    if (name.isEmpty || name.toUpperCase().contains('UNKNOWN')) {
      return null;
    }

    final plants = await ContentRepository.loadPlants();

    final normalized = name.toLowerCase();

    for (final plant in plants) {
      final names = [
        plant.commonName,
        plant.sanskritName ?? '',
        plant.hindiName ?? '',
        plant.scientificName,
      ];

      if (names.any((n) => n.toLowerCase() == normalized)) {
        return plant;
      }
    }

    return null;
  }
}
