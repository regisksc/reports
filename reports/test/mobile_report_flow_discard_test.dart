import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart' as app;
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp(
      'reports-draft-close-',
    );
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await supportDirectory.delete(recursive: true);
  });

  testWidgets(
    'the app-bar close action is labeled and cancellation keeps a draft',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(reduceMotion: true);

      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 22),
        description: 'Keep this report when close is cancelled',
        latitude: 34.05,
        longitude: -118.24,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
      );
      await testStore.saveDraft(draft);
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      final continueDraft = find.descendant(
        of: find.byKey(const Key('home-resume-card')),
        matching: find.text('Continue'),
      );
      await _waitFor(tester, () => continueDraft.evaluate().isNotEmpty);

      await tester.tap(continueDraft);
      await _waitFor(
        tester,
        () => find.byTooltip('Discard draft').evaluate().isNotEmpty,
      );
      expect(find.text('Discard draft'), findsNothing);

      await tester.tap(find.byTooltip('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.text('Discard draft?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Report illegal dumping'), findsOneWidget);
      expect(find.byTooltip('Discard draft'), findsOneWidget);
      final retained = await tester.runAsync(testStore.loadDraft);
      expect(retained?.toJson(), draft.toJson());
    },
  );

  testWidgets('an uncertain submission has no app-bar draft discard action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);

    final attempt = Report(
      description: 'Protected uncertain report',
      latitude: 34.05,
      longitude: -118.24,
      createdAt: DateTime(2026, 10, 21),
      state: ReportState.submissionUncertain,
    );
    await tester.runAsync(() => testStore.saveReport(attempt));
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: ReportFlowPage(
          store: testStore,
          client: _NoSubmissionClient(),
          draft: ReportDraft(
            createdAt: attempt.createdAt,
            description: attempt.description,
            latitude: attempt.latitude,
            longitude: attempt.longitude,
            debrisLocation: 'Curb',
            quantity: '1',
            step: 4,
          ),
        ),
      ),
    );
    await _waitFor(
      tester,
      () => find.textContaining('Do not resend.').evaluate().isNotEmpty,
    );

    expect(find.byTooltip('Discard draft'), findsNothing);
  });
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _NoSubmissionClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) {
    throw StateError('The draft close flow must not submit a report');
  }
}
