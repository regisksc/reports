import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = {
    'name': 'Graffiti Removal',
    'group': 'Graffiti',
    'evidence': 'anonymous available; optional attachments; advertised limit 5',
  };
  testWidgets('catalog and information use Services task headers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: ServiceCatalogPage(onIllegalDumping: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Services'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'Graffiti Removal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Services')),
      findsOneWidget,
    );
    expect(find.text('Save and close'), findsNothing);
  });
  testWidgets('description is multiline and header Back changes steps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: service,
          draft: {
            'id': 'one',
            'step': 1,
            'description': 'Wall',
            'address': 'Main',
            'confirmed': true,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back step'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).first).maxLines, 4);
  });
  testWidgets('photo requirements and review contact details are visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Flooding',
            'group': 'Other',
            'evidence': 'contact required; required attachments',
          },
          draft: {'id': 'one', 'step': 2},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Photos are required for this service.'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          key: ValueKey('review'),
          service: service,
          draft: {
            'id': 'two',
            'step': 4,
            'description': 'Wall',
            'address': 'Main',
            'named': true,
            'firstName': 'Ada',
            'lastName': 'Lovelace',
            'email': 'ada@example.com',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada Lovelace'), findsOneWidget);
    expect(find.textContaining('ada@example.com'), findsOneWidget);
  });
}
