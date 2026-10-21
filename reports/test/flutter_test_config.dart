import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  late BuiltInMapCachingProvider cache;
  late Directory cacheDirectory;
  setUpAll(() {
    Directory('.dart_tool').createSync(recursive: true);
    cacheDirectory = Directory('.dart_tool').createTempSync('map-tile-test-');
    cache = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: cacheDirectory.absolute.path,
      maxCacheSize: null,
      readOnly: true,
    );
  });
  tearDownAll(() async {
    await cache.destroy(deleteCache: true);
  });
  await testMain();
}
