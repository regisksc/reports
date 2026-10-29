import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  testWidgets('waits for remembered contact before showing editable fields', (
    tester,
  ) async {
    final store = _DelayedStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
          },
          draft: {'id': 'one', 'step': 3, 'named': true},
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    store.ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
  });
}

class _DelayedStore extends InMemorySharedPreferencesStore {
  _DelayedStore()
    : super.withData({
        'flutter.reports_saved_contact_v1':
            '{"first":"Ada","last":"Lovelace","email":"ada@example.com","phone":"123"}',
      });
  final ready = Completer<void>();
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    await ready.future;
    return super.getAllWithParameters(parameters);
  }
}
