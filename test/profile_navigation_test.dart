import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/data/sample_data.dart';
import 'package:jeevan_sutra/main.dart';
import 'package:jeevan_sutra/screens/diet_screen.dart';
import 'package:jeevan_sutra/screens/dosha_assessment_screen.dart';
import 'package:jeevan_sutra/screens/profile_screen.dart';
import 'package:jeevan_sutra/services/local_storage_service.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:jeevan_sutra/widgets/app_bar_and_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final dosha in <String>[
    'Vata',
    'Pitta',
    'Kapha',
    'Tridoshic Balanced',
    'Tridoshic (Balanced)',
    'Pitta-Vata',
    'Legacy',
  ]) {
    testWidgets('Health Profile accepts saved constitution $dosha', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_dosha': dosha,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: JeevanSutraTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final dropdowns = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      final constitution = dropdowns.singleWhere(
        (dropdown) => dropdown.value == dosha,
      );
      expect(
        constitution.items!.where((item) => item.value == dosha),
        hasLength(1),
      );
    });
  }

  testWidgets('Health Profile refreshes persisted changes when activated', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_name': 'First name',
      'user_dosha': 'Pitta-Kapha',
    });
    Widget profile(int refreshToken) => MaterialApp(
      theme: JeevanSutraTheme.lightTheme,
      home: ProfileScreen(refreshToken: refreshToken),
    );
    await tester.pumpWidget(profile(0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'First name',
    );

    await LocalStorageService.instance.saveProfileName('Updated name');
    await LocalStorageService.instance.saveDosha('Vata');
    await tester.pumpWidget(profile(1));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Updated name',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Updated name',
    );
  });

  testWidgets('assessment saves a result without an external callback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: const DoshaAssessmentScreen(),
      ),
    );
    await tester.pumpAndSettle();

    for (var question = 0; question < 6; question++) {
      final answer = find.text('Vata Tendency');
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
    }

    expect(await LocalStorageService.instance.getDosha(), 'Vata');
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer selection returns to the current tab after back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_name': 'Repair tester',
    });
    final originalProfileName = SampleData.defaultProfile.name;
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: MainNavigationContainer(isDarkMode: false, onToggleTheme: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(SampleData.defaultProfile.name, originalProfileName);

    await tester.tap(find.byTooltip('Open Navigation Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalized Diet'));
    await tester.pumpAndSettle();
    expect(find.byType(DietScreen), findsOneWidget);

    final dietContext = tester.element(find.byType(DietScreen));
    Navigator.of(dietContext).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open Navigation Menu'));
    await tester.pumpAndSettle();
    final drawer = tester.widget<JeevanSutraDrawer>(
      find.byType(JeevanSutraDrawer),
    );
    expect(drawer.currentRoute, 'home');
    expect(drawer.profile.name, 'Repair tester');
    expect(tester.takeException(), isNull);
  });
}
