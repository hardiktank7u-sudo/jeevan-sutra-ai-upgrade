import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
  final bool isToxic;
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
    this.isToxic = false,
    this.toxicityWarning,
    this.matchedLocalPlant,
  });
}

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  static const String modelName = String.fromEnvironment(
    'FIREBASE_AI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  static const _requestTimeout = Duration(seconds: 60);

  static const String _systemInstruction = '''
You are Jeevan Sutra AI, an educational guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.

Your mission is to explain traditional Indian knowledge alongside modern scientific understanding in a clear and responsible way.

You specialize in:
- Ayurvedic fundamentals such as Tridosha, Vata, Pitta, Kapha, Dinacharya and Ritucharya.
- Indian medicinal plants and herbs.
- Yoga, Pranayama, meditation and mindful living.
- Wholesome nutrition and traditional Ahara principles.
- Indian Knowledge Systems and traditional scientific knowledge.

IMPORTANT SAFETY RULES:
1. You are an educational wellness assistant, NOT a doctor.
2. Never diagnose diseases.
3. Never prescribe medicines or treatment doses.
4. Never tell users to stop or replace prescribed medical treatment.
5. For serious, persistent or concerning symptoms, recommend speaking with a qualified healthcare professional.
6. Clearly distinguish traditional knowledge from modern scientific evidence.
7. Do not present traditional claims as scientifically proven unless supported by evidence.
8. Mention relevant safety concerns when discussing medicinal plants.
9. Do not encourage unsafe self-treatment.
10. Protect user privacy.

STYLE:
- Be warm, calm and encouraging.
- Use clear Markdown.
- Use short sections and bullet points.
- Explain difficult concepts simply.
- You may begin with "Namaste 🙏".
''';

  Future<String?> getApiKey() async {
    return null;
  }

  Future<bool> hasApiKey() async {
    return true;
  }

  @visibleForTesting
  static List<Content> buildChatHistory(
    List<Map<String, dynamic>> conversationHistory,
  ) {
    final messages = <Content>[];
    for (final message in conversationHistory) {
      final text = (message['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      final role =
          message['role'] ?? (message['isUser'] == true ? 'user' : 'model');
      if (role == 'user') {
        messages.add(Content.text(text));
      } else if (role == 'model') {
        messages.add(Content.model([TextPart(text)]));
      }
    }
    final recent = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;
    // Truncating a long conversation can leave an orphaned model turn.
    while (recent.isNotEmpty && recent.first.role != 'user') {
      recent.removeAt(0);
    }
    return recent;
  }

  @visibleForTesting
  static Map<String, dynamic> decodePlantResponse(String response) {
    final clean = response
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    final decoded = jsonDecode(clean);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Plant analysis must be a JSON object.');
    }
    if (decoded['plantName'] is! String) {
      throw const FormatException('Plant analysis is missing its plant name.');
    }
    return decoded;
  }

  static String imageMimeType(Uint8List bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    if (startsWith([0xff, 0xd8, 0xff])) return 'image/jpeg';
    if (startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp') {
      final brand = ascii.decode(bytes.sublist(8, 12), allowInvalid: true);
      if (['heic', 'heix', 'hevc', 'hevx'].contains(brand)) return 'image/heic';
      if (['mif1', 'msf1', 'heif'].contains(brand)) return 'image/heif';
    }
    throw const FormatException(
      'Choose a JPEG, PNG, WebP, or HEIF plant photo.',
    );
  }

  static String describeFailure(Object error) {
    if (error is TimeoutException) {
      return 'The AI service took too long to respond. Please retry.';
    }
    if (error is InvalidApiKey || error is ServiceApiNotEnabled) {
      return 'AI access is not configured for this app. Please contact support.';
    }
    if (error is QuotaExceeded) {
      return 'The AI service is at its usage limit. Please try again later.';
    }
    if (error is UnsupportedUserLocation) {
      return 'The AI service is not available in your region.';
    }
    if (error is FormatException) {
      return error.message.startsWith('Choose a ')
          ? error.message
          : 'The AI service returned an incomplete plant analysis. Please retry with a clear photo.';
    }
    final detail = error.toString().toLowerCase();
    if (detail.contains('appcheck') ||
        detail.contains('app check') ||
        detail.contains('attestation')) {
      return 'AI access could not be verified. Please try again later.';
    }
    if (detail.contains('not found') || detail.contains('not_found')) {
      return 'The configured AI model is unavailable. Please try again later.';
    }
    if (detail.contains('no-app') || detail.contains('permission_denied')) {
      return 'AI access is not configured for this app. Please contact support.';
    }
    return 'Please check your connection and try again.';
  }

  GenerativeModel _createChatModel() {
    final firebaseAI = FirebaseAI.googleAI();

    return firebaseAI.generativeModel(
      model: modelName,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1200,
      ),
    );
  }

  Stream<String> streamChatResponse({
    required String prompt,
    required List<Map<String, dynamic>> conversationHistory,
  }) async* {
    try {
      final model = _createChatModel();

      final chat = model.startChat(
        history: buildChatHistory(conversationHistory),
      );

      final responseStream = chat.sendMessageStream(Content.text(prompt));

      var receivedText = false;
      await for (final chunk in responseStream.timeout(_requestTimeout)) {
        final text = chunk.text;

        if (text != null && text.isNotEmpty) {
          receivedText = true;
          yield text;
        }
      }
      if (!receivedText) {
        yield 'The AI guide could not produce a response. Please try rephrasing your question.';
      }
    } catch (e) {
      yield '''
### Connection issue

I couldn't connect to Jeevan Sutra AI right now.

${describeFailure(e)}
''';
    }
  }

  Future<PlantScanResult> analyzePlantImage(Uint8List imageBytes) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: modelName,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'plantName': Schema.string(),
              'sanskritName': Schema.string(nullable: true),
              'hindiName': Schema.string(nullable: true),
              'scientificName': Schema.string(nullable: true),
              'confidence': Schema.number(minimum: 0, maximum: 1),
              'identification': Schema.string(),
              'traditionalUses': Schema.string(),
              'scientificEvidence': Schema.string(),
              'safetySummary': Schema.string(),
              'precautions': Schema.array(items: Schema.string()),
              'isToxic': Schema.boolean(),
              'toxicityWarning': Schema.string(nullable: true),
            },
          ),
        ),
      );

      const prompt = '''
You are an expert botanical researcher and educational guide to Indian medicinal plants.

Analyze the supplied botanical photograph carefully.

Return ONLY valid JSON:

{
  "plantName": "Common English Name",
  "sanskritName": "Sanskrit name if known",
  "hindiName": "Hindi name if known",
  "scientificName": "Genus species if reasonably identifiable",
  "confidence": 0.0,
  "identification": "Visible botanical characteristics",
  "traditionalUses": "Traditional Ayurvedic or Indian uses",
  "scientificEvidence": "Relevant scientific evidence",
  "safetySummary": "General safety information",
  "precautions": ["precaution 1", "precaution 2"],
  "isToxic": false,
  "toxicityWarning": null
}

Rules:
- confidence must be between 0.0 and 1.0.
- Do not invent certainty.
- If the image is not a plant or identification is unreliable, use "Unidentified Botanical".
- Never provide medical diagnosis or prescriptions.
- Do not claim that a plant can cure a disease.
- Clearly separate traditional uses from scientific evidence.
- Return ONLY valid JSON.
''';

      final response = await model
          .generateContent([
            Content.multi([
              TextPart(prompt),
              InlineDataPart(imageMimeType(imageBytes), imageBytes),
            ]),
          ])
          .timeout(_requestTimeout);

      final responseText = response.text?.trim() ?? '';

      if (responseText.isNotEmpty) {
        final data = decodePlantResponse(responseText);

        final plantName = data['plantName']?.toString().trim() ?? '';

        final scientificName = data['scientificName']?.toString();
        final sanskritName = data['sanskritName']?.toString();

        final matched = await _findMatchingLocalPlant(
          plantName: plantName,
          scientificName: scientificName,
          sanskritName: sanskritName,
        );

        final rawConfidence = data['confidence'];
        final confidence = rawConfidence is num
            ? rawConfidence.toDouble()
            : double.tryParse(rawConfidence?.toString() ?? '') ?? 0.0;
        return PlantScanResult(
          plantName: plantName.isEmpty ? 'Unidentified Botanical' : plantName,
          sanskritName: sanskritName,
          hindiName: data['hindiName']?.toString(),
          scientificName: scientificName,
          confidence: confidence.isFinite
              ? confidence.clamp(0.0, 1.0).toDouble()
              : 0.0,
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
              (data['precautions'] is List ? data['precautions'] as List : null)
                  ?.map((item) => item.toString())
                  .toList() ??
              const [],
          isToxic: data['isToxic'] == true,
          toxicityWarning: data['toxicityWarning']?.toString(),
          matchedLocalPlant: matched,
        );
      }
    } catch (error) {
      return _unavailablePlantResult(describeFailure(error));
    }

    return _unavailablePlantResult();
  }

  PlantScanResult _unavailablePlantResult([String? reason]) => PlantScanResult(
    plantName: 'Unable to identify plant',
    confidence: 0.0,
    identification: reason ?? 'AI analysis could not complete. Retry with a clear photo of one plant.',
    traditionalUses:
        'Not shown because the plant could not be identified reliably.',
    scientificEvidence:
        'Not shown because the plant could not be identified reliably.',
    safetySummary: 'Do not consume or use an unidentified plant medicinally.',
  );
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
          pLower.isNotEmpty &&
          localCommonName.isNotEmpty &&
          (localCommonName.contains(pLower) ||
              pLower.contains(localCommonName));

      final scientificMatches =
          sLower.isNotEmpty &&
          localScientificName.isNotEmpty &&
          (localScientificName.contains(sLower) ||
              sLower.contains(localScientificName));

      final sanskritMatches =
          skLower.isNotEmpty &&
          localSanskritName != null &&
          localSanskritName.isNotEmpty &&
          (localSanskritName.contains(skLower) ||
              skLower.contains(localSanskritName));

      if (nameMatches || scientificMatches || sanskritMatches) {
        return plant;
      }
    }

    return null;
  }
}
