import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows saved previews and removes a local record', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"1","service":"Graffiti Removal","step":5,"description":"Wall","address":"Main Street"}]',
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal'));
    await tester.pumpAndSettle();
    expect(find.text('Wall'), findsOneWidget);
    expect(find.textContaining('not sent'), findsOneWidget);
    await tester.tap(find.text('Remove local record'));
    await tester.pumpAndSettle();
    expect(find.text('No local previews yet'), findsOneWidget);
  });
}
