import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/home/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'support/native_app_test_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('motion preference persists across app restarts', (tester) async {
    final store = MemoryReportStore();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onMotionChanged(true);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_device_preferences_v1',
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).reduceMotion,
      isTrue,
    );
    expect(
      MediaQuery.of(tester.element(find.byType(HomeScreen))).disableAnimations,
      isTrue,
    );
  });
  testWidgets('system reduce motion applies when app preference is off', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).reduceMotion,
      isFalse,
    );
    expect(
      MediaQuery.of(tester.element(find.byType(HomeScreen))).disableAnimations,
      isTrue,
    );
  });

  testWidgets('late restore does not override a newer motion choice', (
    tester,
  ) async {
    final platform = _DelayedLoadStore();
    SharedPreferencesStorePlatform.instance = platform;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onMotionChanged(true);
    await tester.pump();
    platform.ready.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).reduceMotion,
      isTrue,
    );
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_device_preferences_v1',
      ),
      isTrue,
    );
  });

  testWidgets('save failure keeps session choice and reports it', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _FailingSetStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onMotionChanged(true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).reduceMotion,
      isTrue,
    );
    expect(
      find.text(
        'Motion preference could not be saved. It applies for this session.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('rapid motion changes persist in the order chosen', (
    tester,
  ) async {
    final platform = _DelayedFirstSetStore();
    SharedPreferencesStorePlatform.instance = platform;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    home.onMotionChanged(true);
    await tester.pump();
    home.onMotionChanged(false);
    await tester.pump();
    platform.ready.complete();
    await tester.pumpAndSettle();
    await (await SharedPreferences.getInstance()).reload();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_device_preferences_v1',
      ),
      isFalse,
    );
  });
  testWidgets('load failure reports session fallback', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingLoadStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).reduceMotion,
      isFalse,
    );
    expect(
      find.text(
        'Motion preference could not be loaded. Using the session setting.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('system motion changes update the running app', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);
    tester.binding.handleAccessibilityFeaturesChanged();
    await tester.pump();
    expect(
      MediaQuery.of(tester.element(find.byType(HomeScreen))).disableAnimations,
      isTrue,
    );
  });
  testWidgets('superseded save failure does not misreport the latest choice', (
    tester,
  ) async {
    final platform = _DelayedFirstFailureStore();
    SharedPreferencesStorePlatform.instance = platform;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    home.onMotionChanged(true);
    await tester.pump();
    home.onMotionChanged(false);
    await tester.pump();
    platform.ready.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Motion preference could not be saved. It applies for this session.',
      ),
      findsNothing,
    );
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_device_preferences_v1',
      ),
      isFalse,
    );
  });
  testWidgets('settings reflects preference restored after it opens', (
    tester,
  ) async {
    final platform = _DelayedLoadStore(initial: true);
    SharedPreferencesStorePlatform.instance = platform;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    platform.ready.complete();
    await tester.pumpAndSettle();
    final motionSwitch = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(motionSwitch).value, isTrue);
  });
}

class _DelayedLoadStore extends InMemorySharedPreferencesStore {
  _DelayedLoadStore({bool initial = false})
    : super.withData({'flutter.reports_device_preferences_v1': initial});
  final ready = Completer<void>();
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    await ready.future;
    return super.getAllWithParameters(parameters);
  }
}

class _FailingSetStore extends InMemorySharedPreferencesStore {
  _FailingSetStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _DelayedFirstSetStore extends InMemorySharedPreferencesStore {
  _DelayedFirstSetStore() : super.empty();
  final ready = Completer<void>();
  bool first = true;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (first) {
      first = false;
      await ready.future;
    }
    return super.setValue(valueType, key, value);
  }
}

class _FailingLoadStore extends InMemorySharedPreferencesStore {
  _FailingLoadStore() : super.empty();
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async => throw StateError('failed');
}

class _DelayedFirstFailureStore extends InMemorySharedPreferencesStore {
  _DelayedFirstFailureStore() : super.empty();
  final ready = Completer<void>();
  bool first = true;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (first) {
      first = false;
      await ready.future;
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}
