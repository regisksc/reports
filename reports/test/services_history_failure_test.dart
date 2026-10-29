import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets('warns when removing a preview cannot be saved', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follow locally'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
    await tester.tap(find.text('Remove local record'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
  });
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore()
    : super.withData({
        'flutter.service_previews_v1':
            '[{"id":"1","service":"Graffiti Removal","step":5,"description":"Wall","address":"Main Street"}]',
      });
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
