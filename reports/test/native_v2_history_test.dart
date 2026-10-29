import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/history_page.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets(
    'saved reports remain scrollable on a narrow phone with large text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: HistoryPage(
            store: MemoryReportStore(),
            client: NoSubmissionClient(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('No reports yet.'), 150);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved-report filters preserve real receipts, uncertain attempts and the draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = MemoryReportStore()
        ..draft = ReportDraft(
          createdAt: DateTime(2026, 10, 28),
          description: 'Keep this draft',
        );
      store.reports.addAll([
        Report(
          createdAt: DateTime(2026, 10, 26),
          description: 'Confirmed report',
          latitude: 34.05,
          longitude: -118.24,
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-SYNTHETIC-CONFIRMED',
        ),
        Report(
          createdAt: DateTime(2026, 10, 27),
          description: 'Unconfirmed report',
          latitude: 34.05,
          longitude: -118.24,
          state: ReportState.submissionUncertain,
        ),
      ]);
      final before = store.reports.map((report) => report.toJson()).toList();
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: HistoryPage(store: store, client: NoSubmissionClient()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Receipts'));
      await tester.pumpAndSettle();
      final receipts = find.text('SR-SYNTHETIC-CONFIRMED').evaluate().length;
      final hiddenAttempt = find.text('Unconfirmed report').evaluate().isEmpty;
      await tester.tap(find.text('Needs confirmation'));
      await tester.pumpAndSettle();
      final attempts = find.text('Unconfirmed report').evaluate().length;
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      final drafts = find.text('Keep this draft').evaluate().length;
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      final resumed = find.byType(ReportFlowPage).evaluate().length;
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        {
          'receipts': receipts,
          'hiddenAttempt': hiddenAttempt,
          'attempts': attempts,
          'drafts': drafts,
          'resumed': resumed,
          'reports': store.reports.map((report) => report.toJson()).toList(),
        },
        {
          'receipts': 1,
          'hiddenAttempt': true,
          'attempts': 1,
          'drafts': 1,
          'resumed': 1,
          'reports': before,
        },
      );
    },
  );
}
