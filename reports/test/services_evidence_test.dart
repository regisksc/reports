import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sample evidence can be removed and steps can go back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Flooding',
            'group': 'Emergency',
            'evidence':
                'anonymous available; required attachments; advertised limit 1',
          },
          draft: {
            'id': '1',
            'step': 2,
            'description': 'Water',
            'address': 'Main Street',
            'confirmed': true,
            'named': false,
            'photos': 0,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add sample evidence'));
    await tester.pumpAndSettle();
    expect(find.text('1 sample evidence'), findsOneWidget);
    await tester.tap(find.text('Remove sample evidence'));
    await tester.pumpAndSettle();
    expect(find.text('1 sample evidence'), findsNothing);
    await tester.tap(find.text('Back step'));
    await tester.pumpAndSettle();
    expect(find.text('Place it on the map.'), findsOneWidget);
  });
}
