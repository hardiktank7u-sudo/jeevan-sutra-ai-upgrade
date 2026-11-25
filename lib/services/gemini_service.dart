import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/plant.dart';
import '../repositories/content_repository.dart';

class PlantScanResult {
  final String plantName;
  final String? sanskritName;
  final String? hindiName;
  final String? scientificName;
  final String? family;
  final String? plantCategory;
  final String? medicinalClassification;
  final String? growingInformation;
  final String organismType;
  final double confidence;
  final bool liveAiAvailable;
  final String identification;
  final String traditionalUses;
  final String scientificEvidence;
  final String safetySummary;
  final List<String> precautions;
  final bool? isToxic;
  final String? toxicityWarning;
  final Plant? matchedLocalPlant;
  final bool isSampleDemonstration;

  const PlantScanResult({
    required this.plantName,
    this.sanskritName,
    this.hindiName,
    this.scientificName,
    this.family,
    this.plantCategory,
    this.medicinalClassification,
    this.growingInformation,
    this.organismType = 'plant',
    required this.confidence,
    this.liveAiAvailable = true,
    required this.identification,
    required this.traditionalUses,
    required this.scientificEvidence,
    required this.safetySummary,
    this.precautions = const [],
    this.isToxic,
    this.toxicityWarning,
    this.matchedLocalPlant,
    this.isSampleDemonstration = false,
  });
}

class GeminiBackendException implements Exception {
  const GeminiBackendException(this.code);

  final String code;

  @override
  String toString() => code;
}

class GeminiService {
  GeminiService._({
    http.Client? httpClient,
    String? backendBaseUrl,
    this._appCheckTokenProvider,
    this._plantLoader,
  }) : _httpClient = httpClient ?? http.Client(),
       _backendBaseUrl = backendBaseUrl ?? _defaultBackendBaseUrl;

  static final GeminiService instance = GeminiService._();

  static const String modelName = 'gemini-3.8-flash';
  static const String _defaultBackendBaseUrl = String.fromEnvironment(
    'GEMINI_BACKEND_BASE_URL',
    defaultValue: 'https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev',
  );

  static const _requestTimeout = Duration(seconds: 60);
  final http.Client _httpClient;
  final String _backendBaseUrl;
  final Future<String?> Function()? _appCheckTokenProvider;
  final Future<List<Plant>> Function()? _plantLoader;

  @visibleForTesting
  GeminiService.forTesting({
    required http.Client httpClient,
    required String backendBaseUrl,
    required Future<String?> Function() appCheckTokenProvider,
    Future<List<Plant>> Function()? plantLoader,
  }) : this._(
         httpClient: httpClient,
         backendBaseUrl: backendBaseUrl,
         appCheckTokenProvider: appCheckTokenProvider,
         plantLoader: plantLoader,
       );

  Future<String?> getApiKey() async {
    return null;
  }

  Future<bool> hasApiKey() async {
    return _backendBaseUrl.isNotEmpty;
  }

  @visibleForTesting
  static List<Map<String, String>> buildChatHistory(
    List<Map<String, dynamic>> conversationHistory,
  ) {
    final messages = <Map<String, String>>[];
    for (final message in conversationHistory) {
      final text = (message['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      final role =
          message['role'] ?? (message['isUser'] == true ? 'user' : 'model');
      if (role == 'user') {
        messages.add({'role': 'user', 'text': text});
      } else if (role == 'model') {
        messages.add({'role': 'model', 'text': text});
      }
    }
    final recent = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;
    // Truncating a long conversation can leave an orphaned model turn.
    while (recent.isNotEmpty && recent.first['role'] != 'user') {
      recent.removeAt(0);
    }
    return recent;
  }

  Future<Map<String, String>> _requestHeaders() async {
    try {
      final token =
          await (_appCheckTokenProvider?.call() ??
              FirebaseAppCheck.instance.getToken());
      debugPrint('[AI_HEADERS] Token retrieved: ${token != null && token.isNotEmpty}');
      if (token == null || token.isEmpty) {
        throw const GeminiBackendException('APP_CHECK_UNAVAILABLE');
      }
      return {'Content-Type': 'application/json', 'X-Firebase-AppCheck': token};
    } on GeminiBackendException {
      rethrow;
    } catch (e) {
      debugPrint('[AI_HEADERS] Token exception: $e');
      throw const GeminiBackendException('APP_CHECK_UNAVAILABLE');
    }
  }

  Uri _endpoint(String name) {
    final base = Uri.tryParse(_backendBaseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      throw const GeminiBackendException('BACKEND_NOT_CONFIGURED');
    }
    return base.resolve('/$name');
  }

  Future<GeminiBackendException> _responseError(
    http.StreamedResponse response,
  ) async {
    if (response.statusCode == 403 || response.statusCode == 401) {
      return const GeminiBackendException('APP_CHECK_REJECTED');
    }
    if (response.statusCode == 429) {
      return const GeminiBackendException('RATE_LIMITED');
    }
    try {
      final body = await response.stream
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return GeminiBackendException(decoded['error'] as String);
      }
    } catch (_) {}
    return GeminiBackendException(
      response.statusCode >= 500 ? 'BACKEND_UNAVAILABLE' : 'INVALID_RESPONSE',
    );
  }

  GeminiBackendException _jsonResponseError(http.Response response) {
    if (response.statusCode == 403 || response.statusCode == 401) {
      return const GeminiBackendException('APP_CHECK_REJECTED');
    }
    if (response.statusCode == 429) {
      return const GeminiBackendException('RATE_LIMITED');
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return GeminiBackendException(decoded['error'] as String);
      }
    } catch (_) {}
    return GeminiBackendException(
      response.statusCode >= 500 ? 'BACKEND_UNAVAILABLE' : 'INVALID_RESPONSE',
    );
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
    if (error is GeminiBackendException) {
      switch (error.code) {
        case 'APP_CHECK_UNAVAILABLE':
        case 'APP_CHECK_REJECTED':
          return 'AI access could not be verified. Please try again later.';
        case 'BACKEND_NOT_CONFIGURED':
          return 'The AI service address is not configured for this app.';
        case 'AI_NOT_CONFIGURED':
          return 'The AI service is not configured. Please contact support.';
        case 'RATE_LIMITED':
        case 'AI_RATE_LIMITED':
          return 'The AI service is busy. Please wait a moment and try again.';
        case 'INVALID_REQUEST':
          return 'The request could not be processed. Please try again.';
        case 'INVALID_RESPONSE':
        case 'INVALID_AI_RESPONSE':
        case 'EMPTY_AI_RESPONSE':
          return 'The AI service returned an incomplete response. Please retry.';
        default:
          return 'The AI service is temporarily unavailable. Please try again later.';
      }
    }
    if (error is FormatException) {
      return error.message.startsWith('Choose a ')
          ? error.message
          : 'The AI service returned an incomplete plant analysis. Please retry with a clear photo.';
    }
    return 'Please check your connection and try again.';
  }

  Stream<String> streamChatResponse({
    required String prompt,
    required List<Map<String, dynamic>> conversationHistory,
  }) async* {
    final request = http.Request('POST', _endpoint('geminiChat'))
      ..headers.addAll(await _requestHeaders())
      ..body = jsonEncode({
        'prompt': prompt,
        'history': buildChatHistory(conversationHistory),
      });
    final response = await _httpClient.send(request).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw await _responseError(response);
    }
    if (response.headers['content-type']?.contains('text/event-stream') !=
        true) {
      throw const GeminiBackendException('INVALID_RESPONSE');
    }

    var receivedText = false;
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(_requestTimeout)) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data == '[DONE]') break;
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) {
        throw const GeminiBackendException('INVALID_RESPONSE');
      }
      if (decoded['error'] is String) {
        throw GeminiBackendException(decoded['error'] as String);
      }
      final text = decoded['text'];
      if (text is String && text.isNotEmpty) {
        receivedText = true;
        yield text;
      }
    }
    if (!receivedText) {
      throw const GeminiBackendException('EMPTY_AI_RESPONSE');
    }
  }

  Future<PlantScanResult> analyzePlantImage(Uint8List imageBytes) async {
    try {
      final endpoint = _endpoint('geminiPlant');
      final headers = await _requestHeaders();
      debugPrint('[AI_CAMERA] POST $endpoint');
      final response = await _httpClient
          .post(
            endpoint,
            headers: headers,
            body: jsonEncode({
              'mimeType': imageMimeType(imageBytes),
              'imageBase64': base64Encode(imageBytes),
            }),
          )
          .timeout(_requestTimeout);
      debugPrint('[AI_CAMERA] Response code: ${response.statusCode}');
      debugPrint('[AI_CAMERA] Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw _jsonResponseError(response);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Plant analysis must be a JSON object.');
      }
      final result = parsePlantScanResult(decoded);
      Plant? matched;
      if (result.organismType == 'plant') {
        try {
          matched = await _findMatchingLocalPlant(
            plantName: result.plantName,
            scientificName: result.scientificName,
            sanskritName: result.sanskritName,
          );
        } catch (_) {
          // A local content lookup must never discard a successful AI result.
        }
      }
      return matched == null
          ? result
          : parsePlantScanResult(decoded, matchedLocalPlant: matched);
    } catch (error, stack) {
      debugPrint('[AI_CAMERA] analyzePlantImage caught error: $error\n$stack');
      return _unavailablePlantResult(describeFailure(error));
    }
  }

  static PlantScanResult parsePlantScanResult(
    Map<String, dynamic> data, {
    Plant? matchedLocalPlant,
  }) {
    String? stringField(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final rawConfidence = data['confidence'];
    final parsedConfidence = rawConfidence is num
        ? rawConfidence.toDouble()
        : double.tryParse(rawConfidence?.toString() ?? '') ?? 0.0;
    final confidence =
        parsedConfidence.isFinite &&
            parsedConfidence >= 0.0 &&
            parsedConfidence <= 1.0
        ? parsedConfidence
        : 0.0;

    const organismTypes = ['plant', 'fungus', 'non-plant', 'uncertain'];
    final rawOrganismType = data['organismType'];
    final reportedType =
        rawOrganismType is String && organismTypes.contains(rawOrganismType)
        ? rawOrganismType
        : 'uncertain';
    final organismType = confidence < 0.6 ? 'uncertain' : reportedType;
    final isPlant = organismType == 'plant';
    const medicinalClassifications = ['medicinal', 'non-medicinal', 'unknown'];
    final rawMedicinalClassification = stringField('medicinalClassification');
    final isToxic = data['isToxic'] is bool ? data['isToxic'] as bool : null;
    final rawToxicityWarning = stringField('toxicityWarning');
    final toxicityWarning =
        rawToxicityWarning ??
        (isToxic == true
            ? 'Potential toxicity was reported. Do not touch or consume this organism.'
            : null);
    final rawPrecautions = data['precautions'];
    final precautions = isPlant && rawPrecautions is List
        ? rawPrecautions.whereType<String>().toList()
        : <String>[];
    precautions.add(
      isPlant
          ? 'Image identification cannot establish safety or edibility. Do not consume based on this result.'
          : 'Do not consume or use an unidentified organism medicinally.',
    );

    final rawName = stringField('plantName');
    final plantName = switch (organismType) {
      'fungus' => 'Fungus detected (not a plant)',
      'non-plant' => 'No plant detected',
      _ => rawName ?? 'Unidentified Botanical',
    };

    return PlantScanResult(
      plantName: plantName,
      sanskritName: isPlant ? stringField('sanskritName') : null,
      hindiName: isPlant ? stringField('hindiName') : null,
      scientificName: isPlant ? stringField('scientificName') : null,
      family: isPlant ? stringField('family') : null,
      plantCategory: isPlant ? stringField('plantCategory') : null,
      medicinalClassification:
          isPlant &&
              medicinalClassifications.contains(rawMedicinalClassification)
          ? rawMedicinalClassification
          : null,
      growingInformation: isPlant ? stringField('growingInformation') : null,
      organismType: organismType,
      confidence: confidence,
      identification: isPlant
          ? stringField('identification') ??
                'Visible plant characteristics were not provided.'
          : switch (organismType) {
              'fungus' => 'A fungus was identified, not a plant.',
              'non-plant' => 'No plant was identified in this image.',
              _ =>
                'The image does not support a reliable plant identification.',
            },
      traditionalUses: isPlant
          ? stringField('traditionalUses') ??
                'Traditional uses were not confidently identified.'
          : 'Not shown because this image is not confidently identified as a plant.',
      scientificEvidence: isPlant
          ? stringField('scientificEvidence') ??
                'No specific scientific evidence was confidently identified.'
          : 'Not shown because this image is not confidently identified as a plant.',
      safetySummary: isPlant
          ? 'Image identification cannot establish safety or edibility. Do not consume or use medicinally based only on this result.'
          : 'This image is not confirmed as a plant. Do not consume or use it medicinally.',
      precautions: precautions,
      isToxic: isToxic,
      toxicityWarning: toxicityWarning,
      matchedLocalPlant: matchedLocalPlant,
    );
  }

  PlantScanResult _unavailablePlantResult([String? reason]) => PlantScanResult(
    plantName: 'Unable to identify plant',
    organismType: 'uncertain',
    confidence: 0.0,
    liveAiAvailable: false,
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
    final plants =
        await (_plantLoader?.call() ?? ContentRepository.loadPlants());

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
