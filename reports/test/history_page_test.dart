import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/presentation/history_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp(
      'history-support-',
    );
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await supportDirectory.delete(recursive: true);
  });

  testWidgets('unavailable history explains checking before another submission', (
    tester,
  ) async {
    PathProviderPlatform.instance = _SupportPath(null);

    await tester.pumpWidget(const MaterialApp(home: HistoryPage(store: testStore,)));
    await tester.pump();

    expect(find.text('Cannot load reports.'), findsOneWidget);
    expect(
      find.text(
        'Check MyLA311 or call 3-1-1 before submitting again. A previous submission may have reached the City.',
      ),
      findsOneWidget,
    );
    expect(find.text('No reports yet.'), findsNothing);
    expect(find.text('Not sent'), findsNothing);
    expect(find.text('Submitted'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('empty history displays No reports yet', (tester) async {
    await _openHistory(tester);

    expect(find.text('No reports yet.'), findsOneWidget);
  });

  testWidgets('empty history presents the Reports guidance card', (
    tester,
  ) async {
    await _openHistory(tester);

    expect(find.text('Your reports'), findsOneWidget);
    expect(
      find.text('Reports you save on this device will appear here.'),
      findsOneWidget,
    );
    final panel = tester.widget<Container>(
      find.byKey(const ValueKey('history-empty-panel')),
    );
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(22));
    expect(
      decoration.border,
      Border.all(color: const Color(0xffe5e5e5), width: 2),
    );
  });

  testWidgets(
    'saved reports use bordered cards with thumbnail and status pills',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Mattress beside the curb',
          latitude: 34.05,
          longitude: -118.24,
          createdAt: DateTime(2026, 3, 16),
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-CARD-1',
        ),
      );

      await _openHistory(tester);

      final card = tester.widget<Card>(
        find.byKey(const ValueKey('report-card-0')),
      );
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect(shape.side, const BorderSide(color: Color(0xffe5e5e5), width: 2));
      expect(
        tester.getSize(find.byKey(const ValueKey('report-thumb-0'))),
        const Size(52, 56),
      );
      final status = tester.widget<Container>(
        find.byKey(const ValueKey('report-status-0')),
      );
      final decoration = status.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.textContaining('SR-CARD-1'), findsOneWidget);
    },
  );

  testWidgets(
    'report details frame the receipt and saved fields in bordered panels',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Sofa near the alley',
          latitude: 34.05,
          longitude: -118.24,
          createdAt: DateTime(2026, 3, 16),
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-PANEL-1',
        ),
      );
      await _openHistory(tester);
      await tester.tap(find.text('Sofa near the alley'));
      await tester.pumpAndSettle();

      final receipt = tester.widget<Card>(
        find.byKey(const ValueKey('report-receipt')),
      );
      final shape = receipt.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      expect(shape.side, const BorderSide(color: Color(0xffe5e5e5), width: 2));
      final details = tester.widget<Container>(
        find.byKey(const ValueKey('report-detail-panel')),
      );
      final decoration = details.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(20));
      expect(
        decoration.border,
        Border.all(color: const Color(0xffe5e5e5), width: 2),
      );
      expect(find.text('Service Request: SR-PANEL-1'), findsOneWidget);
    },
  );

  testWidgets(
    'saved unconfirmed submission stays distinct in history and details',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Response lost after sending',
          latitude: 34.05,
          longitude: -118.24,
          createdAt: DateTime(2026, 3, 16),
          state: ReportState.submissionUncertain,
        ),
      );

      await _openHistory(tester);

      expect(find.text('Submission unconfirmed'), findsOneWidget);
      expect(find.text('Not sent'), findsNothing);
      expect(find.text('Submitted'), findsNothing);

      await tester.tap(find.text('Response lost after sending'));
      await tester.pumpAndSettle();

      expect(find.text('Report details'), findsOneWidget);
      expect(find.text('Submission unconfirmed'), findsOneWidget);
      expect(find.text('Not sent'), findsNothing);
      expect(find.text('Submitted'), findsNothing);
      expect(find.textContaining('Service Request:'), findsNothing);
    },
  );

  testWidgets(
    'saved reports display their descriptions and submission status',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Trash pile near curb',
          latitude: 34.0522,
          longitude: -118.2437,
          createdAt: DateTime(2026, 3, 15, 10, 30),
        ),
      );
      await _saveReport(
        tester,
        Report(
          description: 'Old sofa and mattress',
          latitude: 34.0530,
          longitude: -118.2440,
          createdAt: DateTime(2026, 3, 16, 14),
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-998877',
        ),
      );

      await _openHistory(tester);

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.textContaining('SR-998877'), findsOneWidget);
      expect(find.text('Not sent'), findsOneWidget);
      expect(find.text('Old sofa and mattress'), findsOneWidget);
      expect(find.text('Trash pile near curb'), findsOneWidget);
    },
  );

  testWidgets(
    'opening a submitted report displays its receipt and saved details',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Refrigerator on sidewalk',
          latitude: 34.0535,
          longitude: -118.2445,
          createdAt: DateTime(2026, 3, 16, 12),
          state: ReportState.submitted,
          serviceRequestNumber: 'SR-112233',
          debrisLocation: 'Alley',
          quantity: 1,
        ),
      );
      await _openHistory(tester);

      await tester.tap(find.text('Refrigerator on sidewalk'));
      await tester.pumpAndSettle();

      expect(find.text('Report details'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Service Request: SR-112233'), findsOneWidget);
      expect(find.text('Refrigerator on sidewalk'), findsOneWidget);
      expect(find.text('Alley'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('34.053500, -118.244500'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    },
  );

  testWidgets(
    'opening a local report displays Not sent without a city receipt',
    (tester) async {
      await _saveReport(
        tester,
        Report(
          description: 'Construction debris',
          latitude: 34.0510,
          longitude: -118.2410,
          createdAt: DateTime(2026, 3, 16, 9),
        ),
      );
      await _openHistory(tester);

      await tester.tap(find.text('Construction debris'));
      await tester.pumpAndSettle();

      expect(find.text('Report details'), findsOneWidget);
      expect(find.text('Not sent'), findsOneWidget);
      expect(find.textContaining('Service Request:'), findsNothing);
      expect(find.text('Construction debris'), findsOneWidget);
    },
  );

  testWidgets('a saved photo appears in history and its report details', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('history-photo-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final photo = File('${directory.path}/photo.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    await _saveReport(
      tester,
      Report(
        description: '',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 3, 16),
        photoPath: photo.path,
      ),
    );
    await _openHistory(tester);
    expect(find.text('Illegal dumping'), findsOneWidget);
    expect(find.image(FileImage(photo)), findsOneWidget);

    await tester.tap(find.text('Illegal dumping'));
    await tester.pumpAndSettle();

    expect(find.text('Report details'), findsOneWidget);
    expect(find.image(FileImage(photo)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _saveReport(WidgetTester tester, Report report) async {
  await tester.runAsync(() => testStore.saveReport(report));
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: HistoryPage(store: testStore,key: UniqueKey())));
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
  expect(find.byType(CircularProgressIndicator), findsNothing);
  await tester.pumpAndSettle();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String? path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
