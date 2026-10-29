import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/presentation/recovery_help_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

void main() {
  testWidgets(
    'latest unconfirmed report resumes in its protected view above the hero',
    (tester) async {
      await _prepareStorage();
      final oldDraft = ReportDraft(
        createdAt: DateTime(2026, 10, 21),
        latitude: 34.052235,
        longitude: -118.243683,
        step: 2,
      );
      final uncertain = _uncertainReport(DateTime(2026, 10, 22));
      await testStore.saveDraft(oldDraft);
      final olderFailed = _uncertainReport(
        DateTime(2026, 10, 20),
        state: ReportState.failed,
      );
      await _saveReports([olderFailed, uncertain]);
      final reportsBefore = (await tester.runAsync(testStore.loadReports))!;
      expect(reportsBefore.first.state, ReportState.submissionUncertain);
      expect(
        (await tester.runAsync(testStore.loadDraft))?.createdAt,
        oldDraft.createdAt,
      );

      await tester.pumpWidget(ReportApp(client: _NoSend()));
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('home-resume-card')).evaluate().isNotEmpty,
      );

      final card = find.byKey(const Key('home-resume-card'));
      expect(find.text('Continue your report'), findsOneWidget);
      expect(find.text('UNCONFIRMED'), findsOneWidget);
      expect(
        find.text('Couch beside the alley · Do not resend'),
        findsOneWidget,
      );
      expect(
        tester.getRect(card).width,
        tester.getRect(find.byKey(const Key('home-hero'))).width,
      );
      expect(
        tester.getTopLeft(card).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('home-hero'))).dy),
      );

      await tester.tap(
        find.descendant(of: card, matching: find.text('Continue')),
      );
      await tester.pumpAndSettle();

      final helpPage = find.byType(RecoveryHelpPage);
      expect(helpPage, findsOneWidget);
      expect(
        find.descendant(
          of: helpPage,
          matching: find.textContaining('Do not resend this report.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Call 311'), findsOneWidget);
      expect(find.byType(ReportFlowPage), findsNothing);
      expect(find.text('Submit'), findsNothing);
      expect(
        tester.widget<RecoveryHelpPage>(helpPage).report.createdAt,
        uncertain.createdAt,
      );
      expect(
        (await tester.runAsync(
          testStore.loadReports,
        ))?.map((report) => report.toJson()),
        reportsBefore.map((report) => report.toJson()),
      );
      expect(
        (await tester.runAsync(testStore.loadDraft))?.createdAt,
        oldDraft.createdAt,
      );
    },
  );

  testWidgets('a genuine draft resumes at its saved location and step', (
    tester,
  ) async {
    await _prepareStorage();
    await testStore.saveDraft(
      ReportDraft(
        createdAt: DateTime(2026, 10, 22),
        latitude: 34.052235,
        longitude: -118.243683,
        step: 2,
        description: 'Mattress beside the curb',
      ),
    );

    await tester.pumpWidget(ReportApp(client: _NoSend()));
    await _pumpUntil(
      tester,
      () => find.byKey(const Key('home-resume-card')).evaluate().isNotEmpty,
    );

    final card = find.byKey(const Key('home-resume-card'));
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('Mattress beside the curb · Step 3 of 6'), findsOneWidget);
    expect(
      tester.getRect(card).width,
      tester.getRect(find.byKey(const Key('home-hero'))).width,
    );

    await tester.tap(
      find.descendant(of: card, matching: find.text('Continue')),
    );
    await _pumpUntil(
      tester,
      () => find.text('Step 3 of 6 · Photos').evaluate().isNotEmpty,
    );

    expect(find.byType(ReportFlowPage), findsOneWidget);
  });
}

Report _uncertainReport(
  DateTime createdAt, {
  ReportState state = ReportState.submissionUncertain,
}) => Report(
  description: 'Couch beside the alley',
  latitude: 34.052235,
  longitude: -118.243683,
  debrisLocation: 'Alley',
  quantity: 2,
  createdAt: createdAt,
  state: state,
);

Future<void> _prepareStorage() async {
  SharedPreferences.setMockInitialValues({});
  final previous = PathProviderPlatform.instance;
  final support = Directory.systemTemp.createTempSync('home-resume-');
  PathProviderPlatform.instance = _SupportPath(support.path);
  addTearDown(() async {
    PathProviderPlatform.instance = previous;
    await support.delete(recursive: true);
  });
}

Future<void> _saveReports(List<Report> reports) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setStringList(
    'reports_v2',
    reports.map((report) => jsonEncode(report.toJson())).toList(),
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  if (!ready()) {
    throw StateError('The Home resume card did not become available');
  }
  await tester.pumpAndSettle();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String path;

  @override
  Future<String> getApplicationSupportPath() async => path;
}

class _NoSend implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('The Home resume card must not send reports');
}
