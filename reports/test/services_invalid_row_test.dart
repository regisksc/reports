import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'preserves incomplete saved rows instead of exposing them to history',
    () async {
      const raw = '[{"id":"incomplete"}]';
      SharedPreferences.setMockInitialValues({'service_previews_v1': raw});
      const store = ServicePreviewStore();
      expect(await store.load(), isEmpty);
      expect(
        await store.save({'id': 'new', 'service': 'Graffiti', 'step': 5}),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'service_previews_v1',
        ),
        raw,
      );
      expect(await store.clear(), isTrue);
    },
  );
  test('preserves rows with invalid optional field types', () async {
    const raw = '[{"id":"one","service":"Graffiti","step":5,"description":42}]';
    SharedPreferences.setMockInitialValues({'service_previews_v1': raw});
    const store = ServicePreviewStore();
    expect(await store.load(), isEmpty);
    expect(
      await store.save({'id': 'new', 'service': 'Graffiti', 'step': 5}),
      isFalse,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('service_previews_v1'),
      raw,
    );
  });
}
