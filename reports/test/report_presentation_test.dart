import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/presentation/history_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('Los Angeles dates honor DST and ignore a different local zone', () {
    final cases = <String, String>{
      '2026-03-08T09:59:00Z': '03/08/2026 · 1:59 AM PST (UTC-08:00)',
      '2026-03-08T10:00:00Z': '03/08/2026 · 3:00 AM PDT (UTC-07:00)',
      '2026-11-01T08:59:00Z': '11/01/2026 · 1:59 AM PDT (UTC-07:00)',
      '2026-11-01T09:00:00Z': '11/01/2026 · 1:00 AM PST (UTC-08:00)',
      '2026-07-01T07:00:00Z': '07/01/2026 · 12:00 AM PDT (UTC-07:00)',
      '2026-07-01T19:00:00Z': '07/01/2026 · 12:00 PM PDT (UTC-07:00)',
    };
    final originalLocal = tz.local;
    addTearDown(() => tz.setLocalLocation(originalLocal));
    final outcomes = <String, Object?>{};

    final utcDates = cases.keys.map(DateTime.parse).toList();
    outcomes['utc'] = utcDates.map(formatReportDate).toList();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    outcomes['tokyo'] = utcDates
        .map((date) => formatReportDate(tz.TZDateTime.from(date, tz.local)))
        .toList();
    outcomes['originalInstants'] = utcDates
        .map((date) => date.toIso8601String())
        .toList();

    expect(outcomes, {
      'utc': cases.values.toList(),
      'tokyo': cases.values.toList(),
      'originalInstants': cases.keys
          .map((value) => DateTime.parse(value).toIso8601String())
          .toList(),
    });
  });

  testWidgets('saved states use truthful labels and Los Angeles dates', (
    tester,
  ) async {
    final support = Directory(
      '.dart_tool',
    ).absolute.createTempSync('synthetic-status-');
    final originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _StatusPaths(support.path);
    addTearDown(() {
      PathProviderPlatform.instance = originalPaths;
      support.deleteSync(recursive: true);
    });
    final states = ReportState.values;
    final reports = [
      for (final state in states)
        Report(
          createdAt: DateTime.utc(2026, 3, 8, 10),
          description: 'SYNTHETIC ${state.name}',
          latitude: 34.05,
          longitude: -118.24,
          state: state,
          serviceRequestNumber: 'SR-SYNTHETIC-24-EXACT',
        ),
    ];
    final rows = reports.map((report) => jsonEncode(report.toJson())).toList();
    SharedPreferences.setMockInitialValues({'reports_v2': rows});
    final observations = <Object?>[];
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var index = 0; index < reports.length; index++) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(index),
          home: ReportDetailPage(store: testStore,report: reports[index]),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('report-receipt'));
      final labels = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .toList();
      observations.add({
        'state': reports[index].state.name,
        'label': labels.first.data,
        'color': labels.first.style?.color,
        'date': find
            .text('03/08/2026 · 3:00 AM PDT (UTC-07:00)')
            .evaluate()
            .length,
        'sr': reports[index].serviceRequestNumber,
      });
    }
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HistoryPage(store: testStore,)));
      for (
        var turn = 0;
        turn < 1000 &&
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        turn++
      ) {
        await Future<void>(() {});
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    observations.add({
      'listDates': find
          .text('03/08/2026 · 3:00 AM PDT (UTC-07:00)')
          .evaluate()
          .length,
      'storedRows': preferences.getStringList('reports_v2'),
    });

    expect(observations, [
      for (final state in states)
        {
          'state': state.name,
          'label': switch (state) {
            ReportState.submitted => 'Submitted',
            ReportState.notSent => 'Not sent',
            _ => 'Submission unconfirmed',
          },
          'color': switch (state) {
            ReportState.submitted => const Color(0xff166534),
            ReportState.notSent => const Color(0xff3c3c3c),
            _ => const Color(0xff92400e),
          },
          'date': 1,
          'sr': 'SR-SYNTHETIC-24-EXACT',
        },
      {'listDates': reports.length, 'storedRows': rows},
    ]);
  });
}

class _StatusPaths extends PathProviderPlatform {
  _StatusPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}
