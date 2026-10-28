import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/nearby/nearby_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets('a delayed restore does not overwrite new input', (tester) async {
    final store = _DelayedStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.enterText(
      find.widgetWithText(TextField, 'Area or address'),
      'New area',
    );
    store.ready.complete({
      'flutter.reports_nearby_filters_v1': '{"area":"Old area"}',
    });
    await tester.pumpAndSettle();
    expect(find.text('New area'), findsOneWidget);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Nearby saves and clears filters without City results', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    expect(find.text('No live results'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Area or address'),
      'Hollywood',
    );
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    expect(find.text('Hollywood'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Hollywood'), findsNothing);
  });

  testWidgets('Nearby supports dates, status, districts and map view', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await NearbyPage.clearSavedFilters();
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start date: Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start date: Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('End date: Select date'));
    await tester.tap(find.text('End date: Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('All statuses'));
    await tester.tap(find.text('All statuses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Request type'),
      'Dumping',
    );
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Neighborhood Council District'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Neighborhood Council District'),
      'Central',
    );
    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Council District'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Council District'),
      '4',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map').last);
    await tester.pumpAndSettle();
    expect(find.text('Map unavailable'), findsOneWidget);
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    expect(find.text('Dumping'), findsOneWidget);
    expect(find.text('Central'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Map unavailable'), findsOneWidget);
    await NearbyPage.clearSavedFilters();
  });

  testWidgets('filters survive storage failure for this session', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _UnavailableStore();
    SharedPreferences.resetStatic();
    await NearbyPage.clearSavedFilters();
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Area or address'),
      'Echo Park',
    );
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(const MaterialApp(home: NearbyPage()));
    await tester.pumpAndSettle();
    expect(find.text('Echo Park'), findsOneWidget);
    await NearbyPage.clearSavedFilters();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Nearby shows a service suggestion and returns back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const NearbyPage(serviceNames: ['Illegal dumping']),
                ),
              ),
              child: const Text('Open nearby'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open nearby'));
    await tester.pumpAndSettle();
    expect(find.text('All services (e.g. Illegal dumping)'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open nearby'), findsOneWidget);
  });
}

class _UnavailableStore extends InMemorySharedPreferencesStore {
  _UnavailableStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() async => throw StateError('unavailable');
}

class _DelayedStore extends InMemorySharedPreferencesStore {
  _DelayedStore() : super.empty();
  final ready = Completer<Map<String, Object>>();

  @override
  Future<Map<String, Object>> getAll() => ready.future;
}
