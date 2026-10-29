import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';

void main() {
  testWidgets('shows the known photo requirement before starting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Flooding',
            'group': 'Other',
            'evidence':
                'anonymous available; required attachments; advertised limit 5',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A photo is required for this service.'), findsOneWidget);
  });
}
