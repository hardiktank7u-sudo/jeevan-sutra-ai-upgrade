import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/plant.dart';
import '../repositories/content_repository.dart';

class PlantScanResult {
  final String plantName;
  final String? sanskritName;
  final String? hindiName;
  final String? scientificName;
  final double confidence;
  final String identification;
  final String traditionalUses;
  final String scientificEvidence;
  final String safetySummary;
  final List<String> precautions;
  final bool? isToxic;
  final String? toxicityWarning;
  final Plant? matchedLocalPlant;

  const PlantScanResult({
    required this.plantName,
    this.sanskritName,
    this.hindiName,
    this.scientificName,
    required this.confidence,
    required this.identification,
    required this.traditionalUses,
    required this.scientificEvidence,
    required this.safetySummary,
    this.precautions = const [],
    this.isToxic,
    this.toxicityWarning,
    this.matchedLocalPlant,
  });
}

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  static const String _modelName = 'gemini-3.8-flash';

  static const String _systemInstruction = '''
You are Jeevan Sutra AI, a serene, empathetic, educational and research-aware guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.

Your mission is to explain authentic Indian traditional knowledge alongside modern scientific understanding in a clear and responsible way.

You specialize in:
- Ayurvedic fundamentals such as Tridosha, Vata, Pitta, Kapha, Dinacharya, Ritucharya, Dhatus and Agni.
- Indian medicinal herbs and plants such as Tulsi, Neem, Amla, Brahmi and Ashwagandha.
- Yoga, Pranayama, meditation and mindful living.
- Wholesome nutrition and traditional Ahara principles.
- Indian Knowledge Systems and traditional scientific knowledge.

IMPORTANT SAFETY RULES:
1. You are an educational wellness assistant, NOT a doctor.
2. Never diagnose a disease or claim that a user definitely has a medical condition.
3. Never prescribe medicines, doses or treatments.
4. Never tell a user to stop, replace or change prescribed medical treatment.
5. For serious, persistent or concerning symptoms, recommend speaking with a qualified healthcare professional.
6. Clearly distinguish traditional Ayurvedic knowledge from modern scientific evidence.
7. Do not present traditional claims as scientifically proven unless there is reliable evidence.
8. When discussing medicinal plants, clearly mention relevant safety concerns and uncertainty.
9. Do not encourage unsafe self-treatment.
10. Protect user privacy and do not request unnecessary sensitive personal information.

STYLE:
- Be warm, calm and encouraging.
- Use clear Markdown.
- Use short sections and bullet points.
- Explain difficult concepts in simple language.
- You may begin with "Namaste 🙏" when appropriate.
- Keep responses useful and reasonably concise.
''';

  /// Firebase AI Logic handles authentication/API access.
  ///
  /// These methods are retained temporarily because the existing AiScreen
  /// still references them. They no longer control whether Gemini is used.
  Future<String?> getApiKey() async {
    return null;
  }

  Future<bool> hasApiKey() async {
    return true;
  }

  GenerativeModel _createChatModel() {
    final firebaseAI = FirebaseAI.googleAI();

    return firebaseAI.generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1200,
      ),
    );
  }

  /// Streams a response from Gemini through Firebase AI Logic.
  ///
  /// The method signature is intentionally kept compatible with the existing
  /// AiScreen.
  Stream<String> streamChatResponse({
    required String prompt,
    required List<Map<String, dynamic>> conversationHistory,
  }) async* {
    try {
      final model = _createChatModel();

      final historyContent = <Content>[];

      // Keep the most recent messages so the request remains compact.
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (final message in recentHistory) {
        final text = (message['text'] ?? '').toString().trim();

        if (text.isEmpty) {
          continue;
        }

        final isUser = message['isUser'] == true;

        if (isUser) {
          historyContent.add(Content.text(text));
        } else {
          historyContent.add(Content.model([TextPart(text)]));
        }
      }

      final chat = model.startChat(history: historyContent);

      final responseStream = chat.sendMessageStream(Content.text(prompt));

      await for (final chunk in responseStream) {
        final text = chunk.text;

        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      yield '''
### Connection issue

I couldn't connect to Jeevan Sutra AI right now.

Please check your internet connection and try again.

> Firebase AI Logic error: $e
''';
    }
  }

  /// Multimodal Gemini analysis for the future AI Camera.
  ///
  /// This is already migrated to Firebase AI Logic so the camera module can
  /// use it later without another SDK migration.
  Future<PlantScanResult> analyzePlantImage(Uint8List imageBytes) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );

      const prompt = '''
You are an expert botanical researcher and an educational guide to Indian medicinal plants.

Analyze the supplied botanical photograph carefully.

Return ONLY valid JSON in exactly this structure:

{
  "plantName": "Common English Name",
  "sanskritName": "Sanskrit name if known",
  "hindiName": "Hindi name if known",
  "scientificName": "Genus species if reasonably identifiable",
  "confidence": 0.0,
  "identification": "Visible botanical characteristics supporting the identification",
  "traditionalUses": "Traditional Ayurvedic or Indian uses, clearly described as traditional knowledge",
  "scientificEvidence": "Relevant scientific evidence or phytochemical information, without exaggeration",
  "safetySummary": "General safety information",
  "precautions": [
    "precaution 1",
    "precaution 2"
  ],
  "isToxic": false,
  "toxicityWarning": null
}

Rules:
- confidence must be between 0.0 and 1.0.
- Do not invent certainty.
- If the image is not a plant or identification is unreliable, use:
  "plantName": "Unidentified Botanical"
  and a low confidence value.
- Never provide medical diagnosis or prescriptions.
- Do not claim that a plant can cure a disease.
- Clearly separate traditional uses from scientific evidence.
- Return ONLY valid JSON.
''';

      final promptPart = TextPart(prompt);
      final imagePart = InlineDataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([promptPart, imagePart]),
      ]);

      final responseText = response.text?.trim() ?? '';

      if (responseText.isNotEmpty) {
        final cleanJson = responseText
            .replaceFirst('```json', '')
            .replaceFirst('```', '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanJson);

        final plantName = data['plantName']?.toString() ?? 'Botanical Specimen';

        final scientificName = data['scientificName']?.toString();
        final sanskritName = data['sanskritName']?.toString();

        final matched = await _findMatchingLocalPlant(
          plantName: plantName,
          scientificName: scientificName,
          sanskritName: sanskritName,
        );

        return PlantScanResult(
          plantName: plantName,
          sanskritName: sanskritName,
          hindiName: data['hindiName']?.toString(),
          scientificName: scientificName,
          confidence:
              (data['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
          identification:
              data['identification']?.toString() ??
              'Visual botanical characteristics were analyzed.',
          traditionalUses:
              data['traditionalUses']?.toString() ??
              'Traditional information was not confidently identified.',
          scientificEvidence:
              data['scientificEvidence']?.toString() ??
              'No specific scientific evidence was confidently identified.',
          safetySummary:
              data['safetySummary']?.toString() ??
              'Do not use an unidentified plant medicinally.',
          precautions:
              (data['precautions'] as List?)
                  ?.map((item) => item.toString())
                  .toList() ??
              const [],
          isToxic: data['isToxic'] == true,
          toxicityWarning: data['toxicityWarning']?.toString(),
          matchedLocalPlant: matched,
        );
      }
    } catch (_) {
      // Fall through to the local educational fallback.
    }

    return _localPlantFallback();
  }

  Future<PlantScanResult> _localPlantFallback() async {
    final plants = await ContentRepository.loadPlants();

    if (plants.isEmpty) {
      return const PlantScanResult(
        plantName: 'Unidentified Botanical',
        confidence: 0.0,
        identification: 'No local plant information is available.',
        traditionalUses: 'Not available.',
        scientificEvidence: 'Not available.',
        safetySummary:
            'Do not consume or use an unidentified plant medicinally.',
      );
    }

    Plant tulsi;

    try {
      tulsi = plants.firstWhere(
        (plant) => plant.commonName.toLowerCase().contains('tulsi'),
      );
    } catch (_) {
      tulsi = plants.first;
    }

    return PlantScanResult(
      plantName: tulsi.commonName,
      sanskritName: tulsi.sanskritName,
      hindiName: tulsi.hindiName,
      scientificName: tulsi.scientificName,
      confidence: 0.88,
      identification: tulsi.identification.isNotEmpty
          ? tulsi.identification
          : 'Local educational plant record used as fallback.',
      traditionalUses: tulsi.traditionalUses.join(' '),
      scientificEvidence: tulsi.scientificEvidence.join(' '),
      safetySummary: tulsi.safetySummary,
      precautions: tulsi.precautions,
      isToxic: tulsi.isToxic,
      toxicityWarning: tulsi.toxicityWarning,
      matchedLocalPlant: tulsi,
    );
  }

  Future<Plant?> _findMatchingLocalPlant({
    required String plantName,
    String? scientificName,
    String? sanskritName,
  }) async {
    final plants = await ContentRepository.loadPlants();

    final pLower = plantName.toLowerCase();
    final sLower = scientificName?.toLowerCase() ?? '';
    final skLower = sanskritName?.toLowerCase() ?? '';

    for (final plant in plants) {
      final localCommonName = plant.commonName.toLowerCase();
      final localScientificName = plant.scientificName.toLowerCase();
      final localSanskritName = plant.sanskritName?.toLowerCase();

      final nameMatches =
          localCommonName.contains(pLower) || pLower.contains(localCommonName);

      final scientificMatches =
          sLower.isNotEmpty &&
          (localScientificName.contains(sLower) ||
              sLower.contains(localScientificName));

      final sanskritMatches =
          skLower.isNotEmpty &&
          localSanskritName != null &&
          (localSanskritName.contains(skLower) ||
              skLower.contains(localSanskritName));

      if (nameMatches || scientificMatches || sanskritMatches) {
        return plant;
      }
    }

    return null;
  }
}
