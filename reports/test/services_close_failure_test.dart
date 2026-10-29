import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets('save and close reports a storage failure', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ServicePreviewPage(
                    service: {
                      'name': 'Graffiti Removal',
                      'group': 'Graffiti',
                      'evidence': 'anonymous available; optional attachments',
                    },
                    draft: {'id': 'failed', 'step': 0},
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
  });
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
