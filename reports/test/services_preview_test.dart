import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates a local preview receipt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: ServiceCatalogPage(onIllegalDumping: () {})),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Graffiti Removal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal').last);
    await tester.pumpAndSettle();
    expect(find.text('Graffiti Removal'), findsWidgets);
    await tester.tap(find.text('Start preview'));
    await tester.pumpAndSettle();
    expect(find.text('Example questions'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Graffiti on wall');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Place it on the map.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Main Street');
    await tester.tap(find.text('Confirm sample pin'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A little more context.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Contact'), findsWidgets);
    await tester.tap(find.text('Anonymous'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsWidgets);
    await tester.tap(find.text('Create local receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Local receipt'), findsOneWidget);
    expect(find.textContaining('not sent'), findsWidgets);
  });
}
