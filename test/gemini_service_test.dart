import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/services/gemini_service.dart';

void main() {
  test('chat history preserves roles from the AI screen and saved history', () {
    final history = GeminiService.buildChatHistory([
      {'role': 'user', 'text': 'How can I build a morning routine?'},
      {'role': 'model', 'text': 'Start with a regular wake-up time.'},
      {'isUser': true, 'text': 'What about breakfast?'},
      {'isUser': false, 'text': 'Choose a balanced breakfast.'},
      {'role': 'model', 'text': '  '},
    ]);

    expect(history.map((turn) => turn.role), [
      'user',
      'model',
      'user',
      'model',
    ]);
    expect(
      (history.first.parts.single as TextPart).text,
      'How can I build a morning routine?',
    );
  });

  test('truncated history begins with a user instead of an orphaned reply', () {
    final history = GeminiService.buildChatHistory([
      for (var index = 0; index < 15; index++)
        {'role': index.isEven ? 'user' : 'model', 'text': 'Turn $index'},
    ]);

    expect(history.length, lessThanOrEqualTo(10));
    expect(history.first.role, 'user');
    expect((history.first.parts.single as TextPart).text, 'Turn 6');
    expect((history.last.parts.single as TextPart).text, 'Turn 14');
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
    'configuration and quota failures do not masquerade as poor connectivity',
    () {
      expect(
        GeminiService.describeFailure(InvalidApiKey('private diagnostic')),
        contains('not configured'),
      );
      expect(
        GeminiService.describeFailure(QuotaExceeded('private diagnostic')),
        contains('usage limit'),
      );
      expect(
        GeminiService.describeFailure(TimeoutException('private diagnostic')),
        contains('too long'),
      );
      expect(
        GeminiService.describeFailure(InvalidApiKey('private diagnostic')),
        isNot(contains('private diagnostic')),
      );
    },
  );
}
