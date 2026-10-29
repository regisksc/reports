import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('malformed stored records do not block later writes', () async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1': '["invalid"]',
    });
    const store = ServicePreviewStore();
    expect(await store.load(), isEmpty);
    expect(await store.save({'id': 'new'}), isFalse);
    expect(
      (await SharedPreferences.getInstance()).getString('service_previews_v1'),
      '["invalid"]',
    );
    expect(await store.clear(), isTrue);
    expect(await store.load(), isEmpty);
  });
}
