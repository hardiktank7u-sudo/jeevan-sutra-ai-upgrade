import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/screens/ai_screen.dart';
import 'package:jeevan_sutra/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'reset cancels an active reply and accepts a fresh conversation',
    (tester) async {
      final responses = <StreamController<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: JeevanSutraTheme.lightTheme,
          home: AiScreen(
            responseBuilder: ({required prompt, required conversationHistory}) {
              final controller = StreamController<String>();
              responses.add(controller);
              return controller.stream;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'First question');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(responses, hasLength(1));

      responses.first.add('Partial answer');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reset Conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // A late reply used to append to _messages.last after Reset cleared it.
      responses.first.add(' late text from cancelled request');
      unawaited(responses.first.close());
      await tester.pumpAndSettle();
      expect(find.textContaining('Partial answer'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Fresh question');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(responses, hasLength(2));
      responses.last.add('Fresh answer');
      unawaited(responses.last.close());
      await tester.pumpAndSettle();
      expect(find.text('Fresh answer'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a failed reply ends loading and allows a retry', (tester) async {
    var requestCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: JeevanSutraTheme.lightTheme,
        home: AiScreen(
          responseBuilder: ({required prompt, required conversationHistory}) {
            requestCount++;
            return Stream<String>.error(TimeoutException('unavailable'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.enterText(find.byType(TextField), 'Retry $attempt');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(requestCount, 2);
    expect(find.textContaining('took too long'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
