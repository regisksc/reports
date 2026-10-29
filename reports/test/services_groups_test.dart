import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';

void main() {
  testWidgets('browses groups and opens a service information page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ServiceCatalogPage(onIllegalDumping: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Animal Care and Control'), findsOneWidget);
    expect(find.text('5 services'), findsOneWidget);
    await tester.tap(find.text('Animal Care and Control'));
    await tester.pumpAndSettle();
    expect(find.text('Animal Complaint/Violation'), findsOneWidget);
    await tester.tap(find.text('All services'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no matching service');
    await tester.pumpAndSettle();
    expect(find.text('No services found'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Animal Complaint/Violation',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Animal Complaint/Violation').last);
    await tester.pumpAndSettle();
    expect(find.text('Service information'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Services')),
      findsOneWidget,
    );
  });
}
