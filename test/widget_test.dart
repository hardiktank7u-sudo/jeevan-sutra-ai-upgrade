import 'package:flutter_test/flutter_test.dart';
import 'package:jeevan_sutra/main.dart';

void main() {
  testWidgets('Jeevan Sutra app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const JeevanSutraApp());

    await tester.pump();

    expect(find.byType(JeevanSutraApp), findsOneWidget);
  });
}
