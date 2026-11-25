import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/models/plant.dart';
import 'package:jeevan_sutra/screens/about_screen.dart';
import 'package:jeevan_sutra/screens/plant_detail_screen.dart';
import 'package:jeevan_sutra/screens/settings_screen.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:jeevan_sutra/widgets/botanical_background.dart';
import 'package:jeevan_sutra/widgets/ui_refresh/botanical_background.dart'
    as compatibility;
import 'package:shared_preferences/shared_preferences.dart';

Future<Color?> _pixelAt(WidgetTester tester, GlobalKey key, int x, int y) {
  return tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset = (y * image.width + x) * 4;
    final color = Color.fromARGB(
      bytes!.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
    image.dispose();
    return color;
  });
}

void main() {
  final backgrounds = <String, Widget Function(Widget)>{
    'canonical': (child) => BotanicalBackground(child: child),
    'compatibility': (child) => compatibility.BotanicalBackground(child: child),
  };
  final themes = <String, ThemeData>{
    'light': JeevanSutraTheme.lightTheme,
    'dark': JeevanSutraTheme.darkTheme,
  };

  for (final theme in themes.entries) {
    for (final background in backgrounds.entries) {
      testWidgets('${background.key} canvas stays ${theme.key} over black', (
        tester,
      ) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: theme.value,
              child: ColoredBox(
                color: Colors.black,
                child: RepaintBoundary(
                  key: key,
                  child: background.value(const SizedBox.expand()),
                ),
              ),
            ),
          ),
        );

        // The center is clear of decorative gradients and botanical strokes.
        expect(
          await _pixelAt(tester, key, 400, 300),
          theme.value.scaffoldBackgroundColor,
        );
      });
    }

    testWidgets('pushed ${theme.key} page paints its canvas and returns', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: theme.value,
            home: Builder(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                    child: const Text('Open about'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open about'));
      await tester.pumpAndSettle();

      expect(find.text('About Jeevan Sutra'), findsOneWidget);
      expect(
        await _pixelAt(tester, key, 2, 2),
        theme.value.scaffoldBackgroundColor,
      );
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Open about'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('plant uses remain readable in ${theme.key} mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const use = 'Traditionally prepared as an infusion.';
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.value,
          home: const PlantDetailScreen(
            plant: Plant(
              id: 'test-plant',
              commonName: 'Test plant',
              scientificName: 'Planta exemplum',
              traditionalUses: [use],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uses'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text(use));
      final container = tester
          .widgetList<Container>(
            find.ancestor(of: find.text(use), matching: find.byType(Container)),
          )
          .firstWhere((widget) => widget.decoration is BoxDecoration);
      final background = (container.decoration! as BoxDecoration).color!;
      final foregroundLuminance = text.style!.color!.computeLuminance();
      final backgroundLuminance = background.computeLuminance();
      final lighter = foregroundLuminance > backgroundLuminance
          ? foregroundLuminance
          : backgroundLuminance;
      final darker = foregroundLuminance < backgroundLuminance
          ? foregroundLuminance
          : backgroundLuminance;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings reminders toggle in ${theme.key} mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(theme: theme.value, home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
