import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('back from a preview detail returns to its list', (tester) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"one","service":"Graffiti Removal","step":5}]',
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Find a local preview'), findsOneWidget);
  });
}
