import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets('retains a draft in session when device saving fails', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _FailingStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: {
            'name': 'Graffiti Removal',
            'group': 'Graffiti',
            'evidence': 'anonymous available; optional attachments',
          },
          draft: {
            'id': 'failed',
            'step': 0,
            'description': '',
            'address': '',
            'confirmed': false,
            'named': false,
            'photos': 0,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Wall');
    await tester.pumpAndSettle();
    expect(find.textContaining('Local saving is unavailable'), findsOneWidget);
    final records = await const ServicePreviewStore().load();
    expect(records.first['description'], 'Wall');
  });
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
