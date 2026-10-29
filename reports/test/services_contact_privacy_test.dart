import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('does not save remembered contact until named is selected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'reports_saved_contact_v1':
          '{"first":"Ada","last":"Lovelace","email":"ada@example.com","phone":"123"}',
    });
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
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final unchosen = await const ServicePreviewStore().load();
    expect(unchosen.first.toString(), isNot(contains('Ada')));
    await tester.tap(find.text('Anonymous'));
    await tester.pumpAndSettle();
    final records = await const ServicePreviewStore().load();
    expect(records.first.toString(), isNot(contains('Ada')));
    expect(records.first.toString(), isNot(contains('ada@example.com')));
  });
}
