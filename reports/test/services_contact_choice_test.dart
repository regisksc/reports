import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('requires an explicit contact choice before review', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
          },
          draft: {
            'id': 'one',
            'step': 3,
            'description': 'Wall',
            'address': 'Main Street',
            'confirmed': true,
            'photos': 0,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose how to provide contact information.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Anonymous'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
  });
}
