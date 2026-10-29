import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';

void main() {
  testWidgets('catalog searches and hands illegal dumping to the real flow', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceCatalogPage(onIllegalDumping: () => opened = true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Services')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Illegal Dumping');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Illegal Dumping Item Pickup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start report'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });
}
