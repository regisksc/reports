import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'clear waits for queued preview saves without changing real reports',
    () async {
      SharedPreferences.setMockInitialValues({'reports_v2': 'keep'});
      const store = ServicePreviewStore();
      final save = store.save({'id': 'one', 'service': 'Graffiti Removal'});
      final clear = store.clear();
      await Future.wait([save, clear]);
      expect(await store.load(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reports_v2'), 'keep');
    },
  );
}
