import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/screens/home_screen.dart';
import 'package:jeevan_sutra/screens/ritucharya_screen.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in <double>[320, 360, 393]) {
    testWidgets('Home screen fits a $width logical-pixel viewport', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: JeevanSutraTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agni Consistency Streak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Seasonal wellness fits a $width logical-pixel viewport', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: JeevanSutraTheme.lightTheme,
          home: const RitucharyaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spring Ritu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
