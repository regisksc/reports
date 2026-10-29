import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_detail_page.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets('legacy Review draft shows step six on Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryReportStore()
      ..draft = ReportDraft(
        createdAt: DateTime(2026, 10, 28),
        step: 4,
        description: 'Review this report',
      );
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 6 of 6'), findsOneWidget);
  });

  testWidgets('named receipt shows its submitted contact and selected items', (
    tester,
  ) async {
    final report = Report(
      description: 'Receipt details',
      latitude: 34.0522,
      longitude: -118.2437,
      createdAt: DateTime(2026, 10, 28),
      state: ReportState.submitted,
      serviceRequestNumber: 'C-CONTACT',
      itemFamily: 'Electronic Waste',
      items: const [
        ReportItem(name: 'Computers', quantity: '2', location: 'Curb'),
      ],
      contact: const ReportContact(
        anonymous: false,
        firstName: 'River',
        lastName: 'Test',
        email: 'river@example.com',
        phone: '2135550100',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: ReportDetailPage(store: MemoryReportStore(), report: report),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Contact'), 200);
    expect(
      {
        'contact': find.textContaining('river@example.com').evaluate().length,
        'items': find.textContaining('2 × Computers · Curb').evaluate().length,
      },
      {'contact': 1, 'items': 1},
    );
  });

  testWidgets(
    'correcting a saved report retains its contact and selected items',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final report = Report(
        description: 'Correct these details',
        latitude: 34.0522,
        longitude: -118.2437,
        debrisLocation: 'Curb',
        quantity: 1,
        itemFamily: 'Electronic Waste',
        items: const [
          ReportItem(name: 'Computers', quantity: '2', location: 'Curb'),
        ],
        createdAt: DateTime(2026, 10, 28),
        contact: const ReportContact(
          anonymous: false,
          firstName: 'River',
          lastName: 'Test',
          email: 'river@example.com',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: ReportDetailPage(
            store: MemoryReportStore(),
            report: report,
            client: NoSubmissionClient(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Correct report'));
      await tester.tap(find.text('Correct report'));
      await tester.pumpAndSettle();
      expect(
        {
          'contact': find.textContaining('river@example.com').evaluate().length,
          'items': tester
              .widget<ReportFlowPage>(find.byType(ReportFlowPage))
              .draft
              ?.items
              .map((item) => item.toJson())
              .toList(),
        },
        {
          'contact': 1,
          'items': [
            {'name': 'Computers', 'quantity': '2', 'location': 'Curb'},
          ],
        },
      );
    },
  );
}
