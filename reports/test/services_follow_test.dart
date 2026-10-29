import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('finds a local receipt and follows it on this device', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"local-1","service":"Graffiti Removal","step":5,"description":"Wall","address":"Main Street"}]',
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'local-1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow locally'));
    await tester.pumpAndSettle();
    expect(find.text('Unfollow locally'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('service_previews_v1'),
      contains('"following":true'),
    );
  });
}
