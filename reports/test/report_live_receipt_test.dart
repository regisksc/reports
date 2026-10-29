import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a retained receipt copies its number and returns home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final copied = <Object?>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add(call.arguments);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final created = DateTime(2026);
    final store = _ReceiptStore()
      ..reports.add(
        Report(
          createdAt: created,
          description: 'Synthetic receipt',
          latitude: 34,
          longitude: -118,
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-EXAMPLE',
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _Accepted(),
                    draft: ReportDraft(
                      createdAt: created,
                      step: 5,
                      flowVersion: 2,
                      latitude: 34,
                      longitude: -118,
                    ),
                  ),
                ),
              ),
              child: const Text('Open receipt'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open receipt'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copy number'));
    await tester.tap(find.text('Copy number'));
    await tester.pumpAndSettle();
    expect(copied, [
      {'text': 'SR-EXAMPLE'},
    ]);
    expect(find.text('Number copied'), findsOneWidget);
    await tester.ensureVisible(find.text('Back to home'));
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('Open receipt'), findsOneWidget);
    expect(store.reports.single.serviceRequestNumber, 'SR-EXAMPLE');
    await tester.tap(find.text('Open receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open receipt'), findsOneWidget);
  });

  testWidgets('copy failure preserves an accepted number when saving failed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'unavailable');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final store = _ReceiptStore()..failReplacement = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: store,
          client: _Accepted(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            step: 5,
            flowVersion: 2,
            latitude: 34,
            longitude: -118,
            debrisLocation: 'Curb',
            quantity: '1',
            contact: const ReportContact(anonymous: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    expect(find.text('SR-EXAMPLE'), findsOneWidget);
    expect(find.textContaining('could not be saved safely'), findsOneWidget);
    await tester.ensureVisible(find.text('Copy number'));
    await tester.tap(find.text('Copy number'));
    await tester.pumpAndSettle();
    expect(find.text('Could not copy the number'), findsOneWidget);
    expect(find.text('SR-EXAMPLE'), findsOneWidget);
    expect(store.reports.single.state, ReportState.submissionUncertain);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This number could not be saved'),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This number could not be saved'),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back to home'));
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This number could not be saved'),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    expect(find.text('SR-EXAMPLE'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
  });
}

class _Accepted implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) async =>
      SubmissionAccepted('SR-EXAMPLE');
}

class _ReceiptStore implements ReportStore {
  final reports = <Report>[];
  bool failReplacement = false;
  @override
  Future<List<Report>> loadReports() async => reports;
  @override
  Future<void> saveReport(Report report) async => reports.add(report);
  @override
  Future<void> replaceReport(Report before, Report after) async {
    if (failReplacement) throw StateError('unavailable');
    reports[reports.indexOf(before)] = after;
  }

  @override
  Future<ReportDraft?> loadDraft() async => null;
  @override
  Future<void> saveDraft(ReportDraft draft) async {}
  @override
  Future<void> discardDraft(DateTime createdAt) async {}
  @override
  Future<void> removeLocalReceipt(Report report) async {}
}
