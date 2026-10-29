import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('prefills named contact and can remember changes', (
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
            'id': '1',
            'step': 3,
            'description': 'Wall',
            'address': 'Main Street',
            'confirmed': true,
            'named': false,
            'photos': 0,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provide contact details'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Lovelace'), findsOneWidget);
    await tester.ensureVisible(find.text('Remember contact on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remember contact on this device'));
    await tester.scrollUntilVisible(
      find.text('Continue'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'reports_saved_contact_v1',
      ),
      contains('Ada'),
    );
  });
}
