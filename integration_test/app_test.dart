import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:drawing_app/main.dart' as app;

// run from terminal:
// flutter test integration_test
// NOTE: Web devices are not supported for integration tests yet.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tap the clear change button 6 times with 1 second delay',
      (WidgetTester tester) async {
    // setup
    app.main();
    await tester.pumpAndSettle();
    final Finder button = find.byIcon(Icons.add); // find string

    // do
    for (int i = 0; i < 6; i++) {
      await tester.tap(button);
      await Future.delayed(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // test
    expect(find.text('10'), findsOneWidget);
  });
}
