import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/screens/ai_screen.dart';
import 'package:jeevan_sutra/services/local_storage_service.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('answers plant questions offline and restores chat history', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: JeevanSutraTheme.lightTheme, home: const AiScreen()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();

    expect(
      find.textContaining('92 bundled plant records are ready offline'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'What family is Tulsi?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.textContaining('Lamiaceae'), findsOneWidget);
    expect(find.textContaining('No Gemini service is used'), findsOneWidget);
    expect((await LocalStorageService.instance.getChatHistory()), hasLength(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(theme: JeevanSutraTheme.lightTheme, home: const AiScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('What family is Tulsi?'), findsOneWidget);
    expect(find.textContaining('Lamiaceae'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reset clears persisted chat history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: JeevanSutraTheme.lightTheme, home: const AiScreen()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    expect(
      find.textContaining('92 bundled plant records are ready offline'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'How do I identify Neem?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pump();
    expect(find.text('How do I identify Neem?'), findsOneWidget);
    expect((await LocalStorageService.instance.getChatHistory()), hasLength(2));

    final resetButton = find.ancestor(
      of: find.byIcon(Icons.refresh_rounded),
      matching: find.byType(IconButton),
    );
    tester.widget<IconButton>(resetButton).onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('Start New Conversation?'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(await LocalStorageService.instance.getChatHistory(), isEmpty);
    expect(find.text('How do I identify Neem?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders live online Gemini response when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: AiScreen(
          responseBuilder: ({
            required prompt,
            required conversationHistory,
          }) async* {
            yield 'Ayurveda emphasizes balancing the doshas.';
            yield ' Ritucharya guides seasonal routines.';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tell me about Ritucharya');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Ayurveda emphasizes balancing the doshas. Ritucharya guides seasonal routines.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('No Gemini service is used'), findsNothing);
    expect((await LocalStorageService.instance.getChatHistory()), hasLength(2));
  });
}
