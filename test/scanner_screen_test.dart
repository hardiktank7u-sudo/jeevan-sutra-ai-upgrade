import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeevan_sutra/models/plant.dart';
import 'package:jeevan_sutra/screens/plant_detail_screen.dart';
import 'package:jeevan_sutra/screens/scanner_screen.dart';
import 'package:jeevan_sutra/services/gemini_service.dart';
import 'package:jeevan_sutra/services/local_storage_service.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Uint8List> _testPlantImage() async {
  final data = await rootBundle.load('assets/branding/test_plant.jpg');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  testWidgets('camera capture sends the captured bytes to the plant analyzer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final imageBytes = await _testPlantImage();
    ImageSource? requestedSource;
    Uint8List? analyzedBytes;
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (source) async {
            requestedSource = source;
            return XFile.fromData(imageBytes, name: 'camera.jpg');
          },
          plantAnalyzer: (bytes) async {
            analyzedBytes = bytes;
            return const PlantScanResult(
              plantName: 'Garden rose',
              organismType: 'plant',
              confidence: 0.9,
              identification: 'A flowering plant.',
              traditionalUses: 'Not established.',
              scientificEvidence: 'Not established.',
              safetySummary: 'Do not consume.',
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Capture Herb'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(requestedSource, ImageSource.camera);
    expect(analyzedBytes, orderedEquals(imageBytes));
    expect(find.text('Garden rose'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gallery photo enters guided matching against all 92 records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final imageBytes = await _testPlantImage();
    ImageSource? requestedSource;
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (source) async {
            requestedSource = source;
            return XFile.fromData(imageBytes, name: 'leaf.jpg');
          },
        ),
      ),
    );

    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(requestedSource, ImageSource.gallery);
    expect(find.text('GUIDED IDENTIFICATION'), findsOneWidget);
    expect(find.text('Compare against 92 records'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Noticeable aroma'),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Noticeable aroma'));
    await tester.ensureVisible(find.text('Compare against 92 records'));
    await tester.tap(find.text('Compare against 92 records'));
    await tester.pump();

    expect(find.text('Best matching catalogue records'), findsOneWidget);
    expect(find.textContaining('text overlap'), findsWidgets);
    expect(find.textContaining('not image similarity'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'automatic recognition failure keeps the photo for guided matching',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final imageBytes = await _testPlantImage();
      await tester.pumpWidget(
        MaterialApp(
          theme: JeevanSutraTheme.lightTheme,
          home: ScannerScreen(
            imagePicker: (_) async =>
                XFile.fromData(imageBytes, name: 'leaf.jpg'),
            plantAnalyzer: (_) async => throw StateError('model unavailable'),
          ),
        ),
      );

      await tester.tap(find.text('Upload Photo'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();

      expect(find.text('GUIDED IDENTIFICATION'), findsOneWidget);
      expect(
        find.textContaining('Automatic image recognition was unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('offline result clearly says live AI is unavailable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (_) async => XFile.fromData(png, name: 'plant.png'),
          plantAnalyzer: (_) async => const PlantScanResult(
            plantName: 'Unable to identify plant',
            organismType: 'uncertain',
            confidence: 0,
            liveAiAvailable: false,
            identification: 'Please check your connection and try again.',
            traditionalUses: 'Not available.',
            scientificEvidence: 'Not available.',
            safetySummary: 'Do not consume an unidentified plant.',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('LIVE AI UNAVAILABLE'), findsOneWidget);
    expect(
      find.textContaining('This image was not identified by Gemini'),
      findsOneWidget,
    );
    expect(find.text('View Full Monograph'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
    final savedScans = (await SharedPreferences.getInstance()).getStringList(
      'scan_history',
    )!;
    final savedScan = jsonDecode(savedScans.first) as Map<String, dynamic>;
    expect(savedScan['plantName'], 'Uploaded leaf');
    expect(savedScan['confidence'], 0.7);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('non-plant results are labeled and cannot be saved as plants', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (_) async => XFile.fromData(png, name: 'mushroom.png'),
          plantAnalyzer: (_) async => const PlantScanResult(
            plantName: 'Fungus detected (not a plant)',
            organismType: 'fungus',
            confidence: 0.94,
            identification: 'A fungus was identified, not a plant.',
            traditionalUses: 'Not applicable.',
            scientificEvidence: 'No plant-specific evidence applies.',
            safetySummary: 'Do not consume.',
            toxicityWarning: 'Toxicity is unknown.',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Fungus detected (not a plant)'), findsWidgets);
    expect(find.text('Classification: fungus'), findsOneWidget);
    expect(find.byTooltip('Save to Sanctuary Herbarium'), findsNothing);
    expect(find.text('View Full Monograph'), findsNothing);
    final savedScans = (await SharedPreferences.getInstance()).getStringList(
      'scan_history',
    )!;
    final savedScan = jsonDecode(savedScans.first) as Map<String, dynamic>;
    expect(savedScan['plantName'], 'Fungus detected (not a plant)');
    expect(savedScan['organismType'], 'fungus');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('plant family and toxicity warning are visible in scan results', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (_) async => XFile.fromData(png, name: 'leaf.png'),
          plantAnalyzer: (_) async => const PlantScanResult(
            plantName: 'Foxglove',
            scientificName: 'Digitalis purpurea',
            family: 'Plantaginaceae',
            plantCategory: 'flowering herb',
            medicinalClassification: 'medicinal',
            growingInformation: 'Grows in temperate gardens.',
            confidence: 0.94,
            identification: 'A plant with tubular flowers.',
            traditionalUses: 'No use recommended.',
            scientificEvidence: 'Not assessed.',
            safetySummary: 'Potentially toxic.',
            isToxic: true,
            toxicityWarning: 'Potentially toxic; do not consume.',
            matchedLocalPlant: Plant(
              id: 'foxglove',
              commonName: 'Foxglove',
              scientificName: 'Digitalis purpurea',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Family: Plantaginaceae'), findsOneWidget);
    expect(find.text('Category: flowering herb'), findsOneWidget);
    expect(find.text('medicinal'), findsOneWidget);
    expect(find.text('Grows in temperate gardens.'), findsOneWidget);
    expect(find.text('TOXICITY WARNING'), findsOneWidget);
    expect(find.text('Potentially toxic; do not consume.'), findsOneWidget);
    expect(find.text('View Full Monograph'), findsOneWidget);
    final monographButton = find.ancestor(
      of: find.text('View Full Monograph'),
      matching: find.byType(ElevatedButton),
    );
    expect(monographButton, findsOneWidget);
    tester.widget<ElevatedButton>(monographButton).onPressed!.call();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(
      Navigator.of(tester.element(find.byType(ScannerScreen))).canPop(),
      isTrue,
    );
    expect(find.byType(PlantDetailScreen, skipOffstage: false), findsOneWidget);
    final detailFinder = find.byType(PlantDetailScreen, skipOffstage: false);
    final detail = tester.widget<PlantDetailScreen>(detailFinder);
    expect(detail.plant.toxicityWarning, 'Potentially toxic; do not consume.');
    expect(detail.plant.category, 'flowering herb');
    expect(detail.plant.medicinalClassification, 'medicinal');
    expect(detail.plant.growingInformation, 'Grows in temperate gardens.');
    expect(ModalRoute.of(tester.element(detailFinder))?.isCurrent, isTrue);
    final detailTabs = tester
        .widget<TabBar>(
          find.descendant(
            of: detailFinder,
            matching: find.byType(TabBar, skipOffstage: false),
          ),
        )
        .controller!;
    detailTabs.index = 3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.descendant(
        of: find.byType(PlantDetailScreen),
        matching: find.text(
          'Potentially toxic; do not consume.',
          skipOffstage: false,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('non-toxic result without toxicity fields opens safely', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: ScannerScreen(
          imagePicker: (_) async => XFile.fromData(png, name: 'leaf.png'),
          plantAnalyzer: (_) async => const PlantScanResult(
            plantName: 'Tulsi',
            confidence: 0.92,
            identification: 'Visible leaf characteristics.',
            traditionalUses: 'A reported traditional use.',
            scientificEvidence: 'A reported evidence summary.',
            safetySummary: 'Safety is not established by this image.',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Upload Photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final monographButton = find.ancestor(
      of: find.text('View Full Monograph'),
      matching: find.byType(ElevatedButton),
    );
    tester.widget<ElevatedButton>(monographButton).onPressed!.call();
    await tester.pump(const Duration(milliseconds: 400));
    final detailFinder = find.byType(PlantDetailScreen, skipOffstage: false);
    tester
            .widget<TabBar>(
              find.descendant(
                of: detailFinder,
                matching: find.byType(TabBar, skipOffstage: false),
              ),
            )
            .controller!
            .index =
        3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text(
        'Caution: This botanical specimen contains potent compounds. Do not ingest without medical supervision.',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'saved scan records preserve toxic and explicitly non-toxic data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;

      await storage.savePlantRecord(
        const Plant(
          id: 'toxic-scan',
          commonName: 'Foxglove',
          scientificName: 'Digitalis purpurea',
          family: 'Plantaginaceae',
          organismType: 'plant',
          confidence: 0.94,
          isToxic: true,
          toxicityWarning: 'Potentially toxic; do not consume.',
          traditionalUses: ['No use recommended.'],
          scientificEvidence: ['Not assessed.'],
          reviewStatus: 'ai_scan_unverified',
        ),
      );
      await storage.savePlantRecord(
        const Plant(
          id: 'nontoxic-scan',
          commonName: 'Tulsi',
          scientificName: 'Ocimum tenuiflorum',
          organismType: 'plant',
          confidence: 0.92,
          isToxic: false,
          reviewStatus: 'ai_scan_unverified',
        ),
      );

      final records = await storage.getSavedPlantRecords();
      expect(
        records.any(
          (plant) =>
              plant.commonName == 'Foxglove' &&
              plant.isToxic == true &&
              plant.toxicityWarning == 'Potentially toxic; do not consume.',
        ),
        isTrue,
      );
      expect(
        records.any(
          (plant) =>
              plant.commonName == 'Tulsi' &&
              plant.isToxic == false &&
              plant.toxicityWarning == null,
        ),
        isTrue,
      );
    },
  );

  test(
    'fungus, non-plant, and uncertain scans remain separate in storage',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService.instance;
      for (final entry in const [
        ('fungus-scan', 'Fungus detected (not a plant)', 'fungus', false),
        ('nonplant-scan', 'No plant detected', 'non-plant', null),
        ('uncertain-scan', 'Unidentified Botanical', 'uncertain', null),
      ]) {
        await storage.savePlantRecord(
          Plant(
            id: entry.$1,
            commonName: entry.$2,
            scientificName: entry.$2,
            organismType: entry.$3,
            confidence: entry.$3 == 'fungus' ? 0.91 : 0.42,
            isToxic: entry.$4,
            reviewStatus: 'ai_scan_unverified',
          ),
        );
      }

      final records = await storage.getSavedPlantRecords();
      expect(records.any((plant) => plant.organismType == 'fungus'), isTrue);
      expect(records.any((plant) => plant.organismType == 'non-plant'), isTrue);
      expect(records.any((plant) => plant.organismType == 'uncertain'), isTrue);
    },
  );

  test(
    'scan history preserves complete scan fields and legacy entries load',
    () async {
      SharedPreferences.setMockInitialValues({
        'scan_history': [
          jsonEncode({
            'schemaVersion': 2,
            'fileName': 'foxglove.png',
            'plantName': 'Foxglove',
            'scientificName': 'Digitalis purpurea',
            'family': 'Plantaginaceae',
            'organismType': 'plant',
            'confidence': 0.94,
            'isToxic': true,
            'toxicityWarning': 'Potentially toxic; do not consume.',
            'traditionalUses': 'No use recommended.',
            'scientificEvidence': 'Not assessed.',
            'safetySummary': 'Do not consume.',
          }),
          jsonEncode({
            'fileName': 'legacy.png',
            'name': 'Legacy plant',
            'plantName': 'Legacy plant',
            'confidence': 0.7,
          }),
        ],
      });

      final history = await LocalStorageService.instance.getScanHistory();
      expect(history.first['organismType'], 'plant');
      expect(history.first['isToxic'], isTrue);
      expect(
        history.first['toxicityWarning'],
        'Potentially toxic; do not consume.',
      );
      expect(history[1]['fileName'], 'legacy.png');
    },
  );

  testWidgets('confirmed scan-history entries reopen the full monograph', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'scan_history': [
        jsonEncode({
          'schemaVersion': 2,
          'fileName': 'foxglove.png',
          'plantName': 'Foxglove',
          'scientificName': 'Digitalis purpurea',
          'family': 'Plantaginaceae',
          'organismType': 'plant',
          'confidence': 0.94,
          'isToxic': true,
          'toxicityWarning': 'Potentially toxic; do not consume.',
          'traditionalUses': 'No use recommended.',
          'scientificEvidence': 'Not assessed.',
          'safetySummary': 'Do not consume.',
        }),
      ],
    });

    await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
    await tester.pump();
    await tester.tap(find.text('Foxglove'));
    await tester.pumpAndSettle();

    expect(find.byType(PlantDetailScreen), findsOneWidget);
    final detail = tester.widget<PlantDetailScreen>(
      find.byType(PlantDetailScreen),
    );
    expect(detail.plant.toxicityWarning, 'Potentially toxic; do not consume.');
  });

  testWidgets('uncertain scan-history entries reopen without a monograph', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'scan_history': [
        jsonEncode({
          'schemaVersion': 2,
          'fileName': 'uncertain.png',
          'plantName': 'Unidentified Botanical',
          'organismType': 'uncertain',
          'confidence': 0.42,
          'isToxic': null,
          'traditionalUses': 'Not shown.',
          'scientificEvidence': 'Not shown.',
        }),
      ],
    });

    await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
    await tester.pump();
    await tester.tap(find.text('Unidentified Botanical'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlantDetailScreen), findsNothing);
    expect(
      find.text(
        'Do not consume or use this organism medicinally. Identification and safety are unverified.',
      ),
      findsOneWidget,
    );
  });

  test('legacy saved plant and history records remain usable', () async {
    SharedPreferences.setMockInitialValues({
      'saved_plants': ['Tulsi'],
      'scan_history': [
        jsonEncode({
          'name': 'Tulsi',
          'fileName': 'legacy-tulsi.png',
          'plantName': 'Tulsi',
        }),
      ],
    });

    expect(
      await LocalStorageService.instance.getSavedPlants(),
      contains('Tulsi'),
    );
    expect(
      (await LocalStorageService.instance.getScanHistory()).single['name'],
      'Tulsi',
    );
  });

  test('legacy saved plants default missing toxicity fields safely', () {
    final plant = Plant.fromJson({
      'id': 'legacy-tulsi',
      'commonName': 'Tulsi',
      'scientificName': 'Ocimum tenuiflorum',
    });

    expect(plant.isToxic, isNull);
    expect(plant.toxicityWarning, isNull);
  });
}
