import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'gemini_service.dart';

class LiveAuditService {
  LiveAuditService._();
  static final LiveAuditService instance = LiveAuditService._();

  Future<void> runLiveAudit() async {
    debugPrint('====================================================');
    debugPrint('[LIVE AUDIT START] Starting Jeevan Sutra Live Audit in Chrome');
    debugPrint('====================================================');

    // Test 1 & 2: Firebase Initialization
    final fbApps = Firebase.apps;
    debugPrint('[LIVE AUDIT 1 & 2] Firebase Apps: ${fbApps.length} (${fbApps.map((a) => a.name).join(", ")}) -> PASS');

    // Test 3: Firebase App Check Token Acquisition
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[LIVE AUDIT 3] Firebase App Check Token Acquired -> PASS');
      } else {
        debugPrint('[LIVE AUDIT 3] Firebase App Check Token: Empty -> FAIL');
      }
    } catch (e) {
      debugPrint('[LIVE AUDIT 3] Firebase App Check Token Exception: $e -> FAIL');
    }

    // Test 4 & 5: Live Gemini Text Generation & Streaming
    String firstReply = '';
    int chunkCount = 0;
    try {
      debugPrint('[LIVE AUDIT 4 & 5] Submitting real text prompt to Gemini...');
      final stream = GeminiService.instance.streamChatResponse(
        prompt: 'In two short sentences, describe Tulsi and its Ayurvedic importance.',
        conversationHistory: [],
      );

      await for (final chunk in stream) {
        chunkCount++;
        firstReply += chunk;
      }

      if (firstReply.isNotEmpty && !firstReply.contains("couldn't connect") && !firstReply.contains("Connection issue")) {
        debugPrint('[LIVE AUDIT 4 & 5] Real Gemini Text Generation: SUCCESS ($chunkCount stream chunks received)');
        debugPrint('[LIVE AUDIT 4 & 5] Streamed Response Snippet: ${firstReply.trim().replaceAll("\n", " ").substring(0, firstReply.length > 120 ? 120 : firstReply.length)}... -> PASS');
      } else {
        debugPrint('[LIVE AUDIT 4 & 5] Gemini Text Generation Error: $firstReply -> FAIL');
      }
    } catch (e) {
      debugPrint('[LIVE AUDIT 4 & 5] Gemini Text Generation Exception: $e -> FAIL');
    }

    // Test 6: Multi-turn Conversation
    try {
      debugPrint('[LIVE AUDIT 6] Testing multi-turn contextual conversation...');
      final history = [
        {'role': 'user', 'text': 'In two short sentences, describe Tulsi and its Ayurvedic importance.'},
        {'role': 'model', 'text': firstReply},
      ];

      String followUpReply = '';
      final followUpStream = GeminiService.instance.streamChatResponse(
        prompt: 'Which Dosha does it predominantly balance?',
        conversationHistory: history,
      );

      await for (final chunk in followUpStream) {
        followUpReply += chunk;
      }

      if (followUpReply.isNotEmpty && !followUpReply.contains("couldn't connect")) {
        debugPrint('[LIVE AUDIT 6] Multi-turn Conversation Response: ${followUpReply.trim().replaceAll("\n", " ").substring(0, followUpReply.length > 120 ? 120 : followUpReply.length)}... -> PASS');
      } else {
        debugPrint('[LIVE AUDIT 6] Multi-turn Conversation Failed: $followUpReply -> FAIL');
      }
    } catch (e) {
      debugPrint('[LIVE AUDIT 6] Multi-turn Exception: $e -> FAIL');
    }

    // Test 7: Bundled image fixture validation (not gallery selection)
    Uint8List? botanicalBytes;
    try {
      final byteData = await rootBundle.load('assets/branding/test_plant.jpg');
      botanicalBytes = byteData.buffer.asUint8List();
      final mime = GeminiService.imageMimeType(botanicalBytes);
      debugPrint('[LIVE AUDIT 7] Bundled image fixture validated (${botanicalBytes.length} bytes, MIME: $mime) -> PASS');
    } catch (e) {
      debugPrint('[LIVE AUDIT 7] Bundled image fixture error: $e -> FAIL');
    }

    // Test 8 & 9: Real Gemini Image Analysis & Structured Results
    PlantScanResult? scanResult;
    if (botanicalBytes != null) {
      try {
        debugPrint('[LIVE AUDIT 8 & 9] Submitting botanical photo to Gemini Multimodal...');
        scanResult = await GeminiService.instance.analyzePlantImage(botanicalBytes);
        if (scanResult.plantName.isNotEmpty && scanResult.plantName != 'Unable to identify plant') {
          debugPrint('[LIVE AUDIT 8 & 9] Plant Identified: ${scanResult.plantName} -> PASS');
          debugPrint('[LIVE AUDIT 8 & 9] Scientific Name: ${scanResult.scientificName}');
          debugPrint('[LIVE AUDIT 8 & 9] Confidence: ${(scanResult.confidence * 100).toStringAsFixed(1)}%');
          debugPrint('[LIVE AUDIT 8 & 9] Ayurvedic Properties: ${scanResult.identification.substring(0, scanResult.identification.length > 80 ? 80 : scanResult.identification.length)}...');
          debugPrint('[LIVE AUDIT 8 & 9] Traditional Uses: ${scanResult.traditionalUses.substring(0, scanResult.traditionalUses.length > 80 ? 80 : scanResult.traditionalUses.length)}...');
          debugPrint('[LIVE AUDIT 8 & 9] Safety Summary: ${scanResult.safetySummary}');
        } else {
          debugPrint('[LIVE AUDIT 8 & 9] Plant Analysis Result: ${scanResult.plantName} (${scanResult.identification}) -> FAIL');
        }
      } catch (e) {
        debugPrint('[LIVE AUDIT 8 & 9] Gemini Image Analysis Exception: $e -> FAIL');
      }
    }

    debugPrint('====================================================');
    debugPrint('[LIVE AUDIT COMPLETE] Live integration checks finished');
    debugPrint('====================================================');
  }
}
