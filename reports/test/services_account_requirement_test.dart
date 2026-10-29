import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';

void main() {
  testWidgets('explains an account requirement without claiming City access', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Containers',
            'group': 'Refuse',
            'evidence': 'account required; attachments unknown',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('City account is required'), findsOneWidget);
    expect(find.textContaining('No City account'), findsOneWidget);
    expect(
      find.text('No account is needed to explore this report.'),
      findsNothing,
    );
    expect(find.text('Start preview'), findsNothing);
    await tester.tap(find.text('Explore demo sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
