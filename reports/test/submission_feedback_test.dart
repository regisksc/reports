import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/presentation/location_map.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

void main() {
  late Directory support;
  late PathProviderPlatform originalPaths;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    support = await Directory.systemTemp.createTemp('submission-feedback-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(support.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await support.delete(recursive: true);
  });

  testWidgets(
    'a different report stays usable and can complete while the original uncertain attempt remains protected',
    (tester) async {
      final original = Report(
        description: 'Synthetic original unconfirmed report',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 22, 12),
        debrisLocation: 'Curb',
        quantity: 1,
        state: ReportState.submissionUncertain,
      );
      await tester.runAsync(() => testStore.saveReport(original));
      final marker = File('${support.path}/submission-attempt.json');
      final originalBytes = await tester.runAsync(marker.readAsBytes);
      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 23, 12),
        description: 'Synthetic different report',
        latitude: 34.06,
        longitude: -118.25,
        debrisLocation: 'Curb',
        quantity: '2',
      );
      final client = _AcceptedClient();
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFlowPage(store: testStore,client: client, draft: draft),
        ),
      );
      await _until(
        tester,
        () =>
            find
                .textContaining('A submission may already')
                .evaluate()
                .isNotEmpty ||
            find
                    .widgetWithText(FilledButton, 'Continue')
                    .evaluate()
                    .isNotEmpty &&
                tester
                        .widget<FilledButton>(
                          find.widgetWithText(FilledButton, 'Continue'),
                        )
                        .onPressed !=
                    null,
      );
      expect(
        tester.widget<LocationMap>(find.byType(LocationMap)).enabled,
        true,
      );
      expect(find.textContaining('A submission may already'), findsNothing);
      for (var step = 0; step < 4; step++) {
        if (step == 3) {
          final field = find.byType(TextField).first;
          await tester.ensureVisible(field);
          await tester.enterText(field, 'Synthetic edited different report');
        }
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            step == 2 ? 'Skip photo' : 'Continue',
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _until(
        tester,
        () => find.text('Report received.').evaluate().isNotEmpty,
      );
      final reports = await tester.runAsync(testStore.loadReports);
      expect(client.calls, 1);
      expect(client.report?.description, 'Synthetic edited different report');
      expect(reports, hasLength(2));
      expect(
        reports!
            .singleWhere((report) => report.createdAt == original.createdAt)
            .state,
        ReportState.submissionUncertain,
      );
      expect(
        reports
            .singleWhere((report) => report.createdAt == draft.createdAt)
            .serviceRequestNumber,
        'SYNTHETIC-NEW-REPORT',
      );
      expect(await tester.runAsync(marker.readAsBytes), originalBytes);
    },
  );

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'an uncertain send reveals feedback and its Help from a scrolled narrow Review without resending, reduced motion $reduceMotion',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final draft = ReportDraft(
          createdAt: DateTime(2026, 10, 22, 12),
          description: List.filled(
            25,
            'Synthetic offline description.',
          ).join(' '),
          latitude: 34.05,
          longitude: -118.24,
          debrisLocation: 'Curb',
          quantity: '3',
          step: 4,
        );
        await tester.runAsync(() => testStore.saveDraft(draft));
        final client = _UncertainClient();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: ReportFlowPage(store: testStore,client: client, draft: draft),
          ),
        );
        await _until(
          tester,
          () =>
              find
                  .widgetWithText(FilledButton, 'Submit')
                  .evaluate()
                  .isNotEmpty &&
              tester
                      .widget<FilledButton>(
                        find.widgetWithText(FilledButton, 'Submit'),
                      )
                      .onPressed !=
                  null,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -1800));
        await tester.pumpAndSettle();
        final controller = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        final startedScrolled = controller.offset > 0;
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await _until(tester, () => client.calls == 1);
        final marker = File('${support.path}/submission-attempt.json');
        final markerBefore = await tester.runAsync(marker.readAsString);
        final reportsBefore = await tester.runAsync(testStore.loadReports);
        client.reply.complete(
          SubmissionFailed(
            SubmissionFailureKind.uncertain,
            'The submission outcome could not be confirmed.',
          ),
        );
        await _until(
          tester,
          () => find.widgetWithText(FilledButton, 'Submit').evaluate().isEmpty,
        );
        await tester.pumpAndSettle();
        final warning = find.textContaining('Do not resend.');
        final detail = find.text(
          'Submission unconfirmed: The submission outcome could not be confirmed.',
        );
        final warningVisible =
            warning.evaluate().isNotEmpty &&
            tester.getRect(warning).top >= 0 &&
            tester.getRect(warning).bottom <= 640;
        final detailVisible =
            detail.evaluate().isNotEmpty &&
            tester.getRect(detail).top >= 0 &&
            tester.getRect(detail).bottom <= 640;
        final markerAfter = await tester.runAsync(marker.readAsString);
        final reportsAfter = await tester.runAsync(testStore.loadReports);
        final draftAfter = await tester.runAsync(testStore.loadDraft);
        final outcome = {
          'startedScrolled': startedScrolled,
          'warningVisible': warningVisible,
          'detailVisible': detailVisible,
          'step': find.textContaining('Step 5 of 5').evaluate().isNotEmpty,
          'submit': find
              .widgetWithText(FilledButton, 'Submit')
              .evaluate()
              .length,
          'retry': find.text('Retry').evaluate().length,
          'help': find.text('Help with this submission').evaluate().length,
          'calls': client.calls,
          'markerUnchanged': markerBefore == markerAfter,
          'reportsUnchanged':
              reportsBefore!.single.toJson().toString() ==
              reportsAfter!.single.toJson().toString(),
          'state': reportsAfter.single.state,
          'sr': reportsAfter.single.serviceRequestNumber,
          'draft': draftAfter,
          'exception': tester.takeException(),
        };
        expect(outcome, {
          'startedScrolled': true,
          'warningVisible': true,
          'detailVisible': true,
          'step': true,
          'submit': 0,
          'retry': 0,
          'help': 1,
          'calls': 1,
          'markerUnchanged': true,
          'reportsUnchanged': true,
          'state': ReportState.submissionUncertain,
          'sr': null,
          'draft': null,
          'exception': null,
        });
        await tester.tap(find.text('Help with this submission'));
        await tester.pumpAndSettle();
        expect(find.text('Submission unconfirmed'), findsOneWidget);
        expect(find.text(draft.description), findsOneWidget);
        expect(client.calls, 1);
      },
    );
  }
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 1000 && !ready(); i++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  if (!ready()) throw StateError('Offline feedback scenario did not settle');
  await tester.pump(const Duration(milliseconds: 400));
}

class _UncertainClient implements SubmissionClient {
  final reply = Completer<SubmissionResult>();
  var calls = 0;

  @override
  Future<SubmissionResult> send(Report report) {
    calls++;
    return reply.future;
  }
}

class _AcceptedClient implements SubmissionClient {
  var calls = 0;
  Report? report;

  @override
  Future<SubmissionResult> send(Report value) async {
    calls++;
    report = value;
    return SubmissionAccepted('SYNTHETIC-NEW-REPORT');
  }
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
