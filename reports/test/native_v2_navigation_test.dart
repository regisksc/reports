import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:reports/features/services/service_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'support/native_app_test_support.dart';

void main() {
  testWidgets('failed preview clearing warns and preserves real records', (
    tester,
  ) async {
    final original = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = _FailedPreviewClear();
    SharedPreferences.resetStatic();
    addTearDown(() async {
      SharedPreferencesStorePlatform.instance = original;
      SharedPreferences.setMockInitialValues({});
      await const ServicePreviewStore().clear();
    });
    final draft = ReportDraft(createdAt: DateTime(2026, 10, 28));
    final store = MemoryReportStore()..draft = draft;
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    expect(
      {
        'warning': find
            .text('Could not clear all preview data. Please try again.')
            .evaluate()
            .length,
        'draft': identical(store.draft, draft),
      },
      {'warning': 1, 'draft': true},
    );
  });

  testWidgets('saved reports opens other services and starts a new report', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"preview-one","service":"Test preview","step":5}]',
    });
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: MemoryReportStore()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View saved reports'));
    await tester.tap(find.text('View saved reports'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View other service reports'),
      250,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View other service reports'));
    await tester.tap(find.text('View other service reports'));
    await tester.pumpAndSettle();
    expect(find.text('Test preview'), findsOneWidget);
    final previewHistory = find.byType(ServiceHistoryPage).evaluate().length;
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New report'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New report'));
    await tester.tap(find.text('New report'));
    await tester.pumpAndSettle();
    expect(
      {
        'previewHistory': previewHistory,
        'services': find
            .descendant(
              of: find.byType(AppBar),
              matching: find.text('Services'),
            )
            .evaluate()
            .length,
      },
      {'previewHistory': 1, 'services': 1},
    );
  });

  testWidgets('clear preview data keeps the real draft and receipts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1': '[{"id":"preview-one"}]',
      'reports_nearby_filters_v1': '{"area":"Hollywood"}',
    });
    final draft = ReportDraft(createdAt: DateTime(2026, 10, 28));
    final receipt = Report(
      description: 'Keep this receipt',
      latitude: 34.0522,
      longitude: -118.2437,
      createdAt: DateTime(2026, 10, 27),
      state: ReportState.submitted,
      serviceRequestNumber: 'C-KEEP',
    );
    final store = MemoryReportStore()..draft = draft;
    store.reports.add(receipt);
    await tester.pumpWidget(
      ReportApp(client: NoSubmissionClient(), store: store),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 20 && find.text('Local preview data cleared.').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final prefs = await SharedPreferences.getInstance();
    expect(
      {
        'previews': prefs.getString('service_previews_v1'),
        'filters': prefs.getString('reports_nearby_filters_v1'),
        'draft': identical(store.draft, draft),
        'receipt': identical(store.reports.single, receipt),
      },
      {'previews': '[]', 'filters': null, 'draft': true, 'receipt': true},
    );
  });

  testWidgets(
    'Home opens native v2 destinations without tabs or losing a draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final draft = ReportDraft(createdAt: DateTime(2026, 10, 28), step: 2);
      final store = MemoryReportStore()..draft = draft;
      await tester.pumpWidget(
        ReportApp(client: NoSubmissionClient(), store: store),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start a report'));
      await tester.tap(find.text('Start a report'));
      await tester.pumpAndSettle();
      final destinations = <String, int>{
        'services': find
            .descendant(
              of: find.byType(AppBar),
              matching: find.text('Services'),
            )
            .evaluate()
            .length,
      };
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.settings_outlined));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      destinations['settings'] = find
          .descendant(of: find.byType(AppBar), matching: find.text('Settings'))
          .evaluate()
          .length;
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      destinations['account'] = find.text('Your account').evaluate().length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nearby reports'));
      await tester.tap(find.text('Nearby reports'));
      await tester.pumpAndSettle();
      destinations['nearby'] = find
          .descendant(of: find.byType(AppBar), matching: find.text('Nearby'))
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Help and information'));
      await tester.tap(find.text('Help and information'));
      await tester.pumpAndSettle();
      destinations['help'] = find
          .text('Let’s clear things up.')
          .evaluate()
          .length;
      await tester.tap(find.text('How reporting works'));
      await tester.pumpAndSettle();
      destinations['article'] = find
          .text('How reporting works')
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        {
          'destinations': destinations,
          'tabs':
              find.byType(NavigationBar).evaluate().length +
              find.byType(BottomNavigationBar).evaluate().length,
          'draft': store.draft?.createdAt,
          'reports': store.reports.length,
        },
        {
          'destinations': {
            'services': 1,
            'settings': 1,
            'account': 1,
            'nearby': 1,
            'help': 1,
            'article': 1,
          },
          'tabs': 0,
          'draft': draft.createdAt,
          'reports': 0,
        },
      );
    },
  );
}

class _FailedPreviewClear extends InMemorySharedPreferencesStore {
  _FailedPreviewClear() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      key.endsWith('service_previews_v1')
      ? Future.value(false)
      : super.setValue(valueType, key, value);
}
