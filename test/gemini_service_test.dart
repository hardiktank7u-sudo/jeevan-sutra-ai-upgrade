import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jeevan_sutra/services/gemini_service.dart';
import 'package:jeevan_sutra/services/gemini_plant_service.dart';

void main() {
  test('chat history preserves roles from the AI screen and saved history', () {
    final history = GeminiService.buildChatHistory([
      {'role': 'user', 'text': 'How can I build a morning routine?'},
      {'role': 'model', 'text': 'Start with a regular wake-up time.'},
      {'isUser': true, 'text': 'What about breakfast?'},
      {'isUser': false, 'text': 'Choose a balanced breakfast.'},
      {'role': 'model', 'text': '  '},
    ]);

    expect(history.map((turn) => turn['role']), [
      'user',
      'model',
      'user',
      'model',
    ]);
    expect(history.first['text'], 'How can I build a morning routine?');
  });

  test('truncated history begins with a user instead of an orphaned reply', () {
    final history = GeminiService.buildChatHistory([
      for (var index = 0; index < 15; index++)
        {'role': index.isEven ? 'user' : 'model', 'text': 'Turn $index'},
    ]);

    expect(history.length, lessThanOrEqualTo(10));
    expect(history.first['role'], 'user');
    expect(history.first['text'], 'Turn 6');
    expect(history.last['text'], 'Turn 14');
  });

  test('plant response accepts a fenced JSON object', () {
    expect(
      GeminiService.decodePlantResponse('```JSON\n{"plantName":"Tulsi"}\n```'),
      {'plantName': 'Tulsi'},
    );
  });

  test('plant response rejects arrays, invalid JSON, and absent names', () {
    for (final response in ['[]', 'not JSON', '{"confidence":0.9}']) {
      expect(
        () => GeminiService.decodePlantResponse(response),
        throwsFormatException,
      );
    }
  });

  test(
    'missing organism classification abstains and blocks medicinal claims',
    () {
      final result = GeminiService.parsePlantScanResult({
        'plantName': 'Possible herb',
        'scientificName': 'Claimed species',
        'confidence': 0.95,
        'identification': 'A claimed identification.',
        'traditionalUses': 'A claimed use.',
        'scientificEvidence': 'A claimed study.',
        'safetySummary': 'Claimed to be safe.',
      });

      expect(result.organismType, 'uncertain');
      expect(result.scientificName, isNull);
      expect(result.plantName, 'Possible herb');
      expect(result.traditionalUses, contains('Not shown'));
      expect(result.scientificEvidence, contains('Not shown'));
      expect(result.safetySummary, contains('Do not consume'));
      expect(result.precautions.join(' '), contains('Do not consume'));
    },
  );

  test(
    'low-confidence plant and fungi are not presented as confirmed plants',
    () {
      final lowConfidence = GeminiService.parsePlantScanResult({
        'organismType': 'plant',
        'plantName': 'Possible plant',
        'scientificName': 'Claimed species',
        'confidence': 0.4,
        'traditionalUses': 'Claimed use.',
        'scientificEvidence': 'Claimed evidence.',
      });
      final fungus = GeminiService.parsePlantScanResult({
        'organismType': 'fungus',
        'plantName': 'A medicinal plant',
        'scientificName': 'Claimed species',
        'confidence': 0.95,
        'traditionalUses': 'Claimed use.',
        'scientificEvidence': 'Claimed evidence.',
      });

      expect(lowConfidence.organismType, 'uncertain');
      expect(lowConfidence.scientificName, isNull);
      expect(fungus.organismType, 'fungus');
      expect(fungus.plantName, 'Fungus detected (not a plant)');
      expect(fungus.scientificName, isNull);
      expect(fungus.traditionalUses, contains('Not shown'));
      expect(fungus.scientificEvidence, contains('Not shown'));
    },
  );

  test('out-of-range confidence is treated as uncertain', () {
    final result = GeminiService.parsePlantScanResult({
      'organismType': 'plant',
      'plantName': 'Possible plant',
      'confidence': 1.5,
      'scientificName': 'Claimed species',
    });

    expect(result.organismType, 'uncertain');
    expect(result.confidence, 0.0);
    expect(result.scientificName, isNull);
  });

  test('toxic warning survives normalization even if its text is absent', () {
    final result = GeminiService.parsePlantScanResult({
      'organismType': 'plant',
      'plantName': 'Foxglove',
      'confidence': 0.9,
      'isToxic': true,
    });

    expect(result.isToxic, isTrue);
    expect(result.toxicityWarning, contains('Do not touch or consume'));
  });

  test('photos keep their actual MIME type for the AI request', () {
    expect(
      GeminiService.imageMimeType(Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0])),
      'image/jpeg',
    );
    expect(
      GeminiService.imageMimeType(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
      'image/png',
    );
    expect(
      GeminiService.imageMimeType(
        Uint8List.fromList([
          ...ascii.encode('RIFF'),
          0,
          0,
          0,
          0,
          ...ascii.encode('WEBP'),
        ]),
      ),
      'image/webp',
    );
    expect(
      GeminiService.imageMimeType(
        Uint8List.fromList([0, 0, 0, 24, ...ascii.encode('ftypheic')]),
      ),
      'image/heic',
    );
    expect(
      () => GeminiService.imageMimeType(Uint8List(0)),
      throwsFormatException,
    );
    expect(
      () => GeminiService.imageMimeType(
        Uint8List.fromList(ascii.encode('not an image')),
      ),
      throwsFormatException,
    );
  });

  test(
    'unfamiliar AI plants do not depend on bundled local plant records',
    () async {
      final image = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x01]);
      final providerResult = {
        'organismType': 'plant',
        'plantName': 'Blue passionflower',
        'scientificName': 'Passiflora caerulea',
        'family': 'Passifloraceae',
        'plantCategory': 'flowering vine',
        'medicinalClassification': 'unknown',
        'growingInformation': 'Grows on supports in warm, sunny conditions.',
        'hindiName': null,
        'sanskritName': null,
        'confidence': 0.91,
        'identification': 'A climbing vine with distinctive flowers.',
        'traditionalUses': 'No traditional use established.',
        'scientificEvidence': 'No specific evidence established.',
        'safetySummary': 'Do not consume based on image identification.',
        'precautions': ['Identification is unverified.'],
        'isToxic': false,
        'toxicityWarning': null,
      };
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        expect(request.url.path, '/geminiPlant');
        expect(request.headers['X-Firebase-AppCheck'], 'test-app-check');
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(providerResult), 200);
      });
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => 'test-app-check',
        plantLoader: () async =>
            throw const FormatException('Local plant catalogue unavailable'),
      );

      final result = await service.analyzePlantImage(image);

      expect(sentBody?['mimeType'], 'image/jpeg');
      expect(sentBody?['imageBase64'], base64Encode(image));
      expect(result.plantName, 'Blue passionflower');
      expect(result.scientificName, 'Passiflora caerulea');
      expect(result.plantCategory, 'flowering vine');
      expect(result.medicinalClassification, 'unknown');
      expect(
        result.growingInformation,
        'Grows on supports in warm, sunny conditions.',
      );
      expect(result.organismType, 'plant');
      expect(result.liveAiAvailable, isTrue);
      expect(result.matchedLocalPlant, isNull);
      client.close();
    },
  );

  test('plant service returns a new AI plant without a local match', () async {
    final service = GeminiPlantService(
      analyzer: (_) async => const PlantScanResult(
        plantName: 'Blue passionflower',
        scientificName: 'Passiflora caerulea',
        family: 'Passifloraceae',
        plantCategory: 'flowering vine',
        medicinalClassification: 'unknown',
        growingInformation: 'Grows on supports.',
        confidence: 0.91,
        identification: 'A climbing vine.',
        traditionalUses: 'Not established.',
        scientificEvidence: 'Not established.',
        safetySummary: 'Do not consume.',
      ),
    );

    final plant = await service.identifyPlant(Uint8List.fromList([1]));

    expect(plant?.commonName, 'Blue passionflower');
    expect(plant?.scientificName, 'Passiflora caerulea');
    expect(plant?.family, 'Passifloraceae');
    expect(plant?.category, 'flowering vine');
    expect(plant?.medicinalClassification, 'unknown');
    expect(plant?.growingInformation, 'Grows on supports.');
    expect(plant?.reviewStatus, 'ai_scan_unverified');
  });

  test(
    'offline plant scan is explicitly marked as live AI unavailable',
    () async {
      final client = MockClient(
        (_) async => throw const SocketException('offline'),
      );
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => 'test-app-check',
      );

      final result = await service.analyzePlantImage(
        Uint8List.fromList([0xff, 0xd8, 0xff]),
      );

      expect(result.liveAiAvailable, isFalse);
      expect(result.plantName, 'Unable to identify plant');
      expect(result.identification, contains('connection'));
      client.close();
    },
  );

  test(
    'configuration and quota failures do not masquerade as poor connectivity',
    () {
      expect(
        GeminiService.describeFailure(
          const GeminiBackendException('AI_NOT_CONFIGURED'),
        ),
        contains('not configured'),
      );
      expect(
        GeminiService.describeFailure(
          const GeminiBackendException('RATE_LIMITED'),
        ),
        contains('busy'),
      );
      expect(
        GeminiService.describeFailure(TimeoutException('private diagnostic')),
        contains('too long'),
      );
      expect(
        GeminiService.describeFailure(
          const GeminiBackendException('APP_CHECK_REJECTED'),
        ),
        isNot(contains('private diagnostic')),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // streamChatResponse tests
  // ---------------------------------------------------------------------------

  test('streamChatResponse yields text chunks from a valid SSE stream',
      () async {
    final sseBody =
        'data: {"text":"Namaste"}\r\n\r\ndata: {"text":" friend"}\r\n\r\ndata: [DONE]\r\n\r\n';
    final client = MockClient((request) async {
      expect(request.url.path, '/geminiChat');
      expect(request.headers['X-Firebase-AppCheck'], 'test-token');
      return http.Response(
        sseBody,
        200,
        headers: {'content-type': 'text/event-stream; charset=utf-8'},
      );
    });
    final service = GeminiService.forTesting(
      httpClient: client,
      backendBaseUrl: 'https://gemini.test',
      appCheckTokenProvider: () async => 'test-token',
    );

    final chunks = await service
        .streamChatResponse(prompt: 'Hello', conversationHistory: [])
        .toList();

    expect(chunks, ['Namaste', ' friend']);
    client.close();
  });

  test(
    'streamChatResponse throws EMPTY_AI_RESPONSE when no text chunks arrive',
    () async {
      final sseBody = 'data: [DONE]\r\n\r\n';
      final client = MockClient(
        (_) async => http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        ),
      );
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => 'test-token',
      );

      await expectLater(
        service
            .streamChatResponse(prompt: 'Hello', conversationHistory: [])
            .toList(),
        throwsA(
          isA<GeminiBackendException>().having(
            (e) => e.code,
            'code',
            'EMPTY_AI_RESPONSE',
          ),
        ),
      );
      client.close();
    },
  );

  test(
    'streamChatResponse throws AI_UPSTREAM_UNAVAILABLE on 502 from Worker',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"error":"AI_UPSTREAM_UNAVAILABLE"}',
          502,
          headers: {'content-type': 'application/json'},
        ),
      );
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => 'test-token',
      );

      await expectLater(
        service
            .streamChatResponse(prompt: 'Hello', conversationHistory: [])
            .toList(),
        throwsA(
          isA<GeminiBackendException>().having(
            (e) => e.code,
            'code',
            'AI_UPSTREAM_UNAVAILABLE',
          ),
        ),
      );
      client.close();
    },
  );

  test(
    'streamChatResponse throws APP_CHECK_UNAVAILABLE when token is null',
    () async {
      final client = MockClient((_) async => http.Response('', 200));
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => null,
      );

      await expectLater(
        service
            .streamChatResponse(prompt: 'Hello', conversationHistory: [])
            .toList(),
        throwsA(
          isA<GeminiBackendException>().having(
            (e) => e.code,
            'code',
            'APP_CHECK_UNAVAILABLE',
          ),
        ),
      );
      client.close();
    },
  );

  test(
    'streamChatResponse sends prompt and history in the request body',
    () async {
      final sseBody = 'data: {"text":"ok"}\r\n\r\ndata: [DONE]\r\n\r\n';
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });
      final service = GeminiService.forTesting(
        httpClient: client,
        backendBaseUrl: 'https://gemini.test',
        appCheckTokenProvider: () async => 'tok',
      );

      await service
          .streamChatResponse(
            prompt: 'What is Tulsi?',
            conversationHistory: [
              {'role': 'user', 'text': 'Tell me about herbs'},
              {'role': 'model', 'text': 'Herbs are plants used in medicine.'},
            ],
          )
          .drain<void>();

      expect(sentBody?['prompt'], 'What is Tulsi?');
      expect((sentBody?['history'] as List).length, 2);
      client.close();
    },
  );
}
