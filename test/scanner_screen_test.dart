import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeevan_sutra/screens/scanner_screen.dart';
import 'package:jeevan_sutra/services/gemini_service.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('an old sample scan cannot replace a real upload result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final result = Completer<PlantScanResult>();
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (_) async => XFile.fromData(png, name: 'leaf.png'),
          plantAnalyzer: (_) => result.future,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Simulate Sample Scan'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('View Full Monograph'), findsNothing);
    expect(find.textContaining('Analyzing botanical taxonomy'), findsOneWidget);

    result.complete(
      const PlantScanResult(
        plantName: 'Uploaded leaf',
        confidence: 0.7,
        identification: 'Visible leaf characteristics',
        traditionalUses: 'No medicinal use recommended.',
        scientificEvidence: 'No evidence provided.',
        safetySummary: 'Do not consume an unidentified plant.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Uploaded leaf'), findsWidgets);
    expect(find.textContaining('Analyzing botanical taxonomy'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
