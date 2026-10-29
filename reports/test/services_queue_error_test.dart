import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'an unexpected operation error does not block later storage operations',
    () async {
      SharedPreferences.setMockInitialValues({
        'service_previews_v1': '[{"id":"old","service":"Graffiti","step":5}]',
      });
      const store = ServicePreviewStore();
      await expectLater(store.save(_BrokenRecord()), throwsStateError);
      expect(await store.clear(), isTrue);
    },
  );
}

class _BrokenRecord extends MapBase<String, dynamic> {
  @override
  dynamic operator [](Object? key) => throw StateError('invalid record');
  @override
  void operator []=(String key, dynamic value) => throw UnimplementedError();
  @override
  void clear() => throw UnimplementedError();
  @override
  Iterable<String> get keys => const [];
  @override
  dynamic remove(Object? key) => throw UnimplementedError();
}
