import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('local receipt displays the lookup ID', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
          },
          draft: {'id': 'local-123', 'step': 5},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('local-123'), findsOneWidget);
    expect(find.textContaining('not sent'), findsOneWidget);
  });
}
