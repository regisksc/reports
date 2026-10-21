import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/presentation/history_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  testWidgets(
    'a confirmed receipt copies exactly and dismissal preserves saved data',
    (tester) async {
      final support = Directory(
        '.dart_tool',
      ).absolute.createTempSync('synthetic-receipt-');
      final originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _ReceiptPaths(support.path);
      final confirmed = _report(ReportState.submitted, 'SR-SYNTHETIC-20-EXACT');
      final uncertain = Report(
        createdAt: DateTime.utc(2026, 10, 21),
        description: 'Synthetic protected attempt',
        latitude: 34.05,
        longitude: -118.24,
        state: ReportState.submissionUncertain,
      );
      final rows = [
        jsonEncode(confirmed.toJson()),
        jsonEncode(uncertain.toJson()),
      ];
      final markerText = jsonEncode(uncertain.toJson());
      final marker = File('${support.path}/submission-attempt.json')
        ..writeAsStringSync(markerText);
      SharedPreferences.setMockInitialValues({'reports_v2': rows});
      final copied = <Object?>[];
      final shared = <MethodCall>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments);
        return null;
      });
      messenger.setMockMethodCallHandler(_shareChannel, (call) async {
        shared.add(call);
        return '';
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        messenger.setMockMethodCallHandler(_shareChannel, null);
        PathProviderPlatform.instance = originalPaths;
        support.deleteSync(recursive: true);
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: ReportDetailPage(store: testStore,report: confirmed)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share receipt'));
      await tester.pumpAndSettle();
      final preferences = await SharedPreferences.getInstance();
      final arguments = shared.isEmpty
          ? <Object?, Object?>{}
          : shared.first.arguments as Map;
      final origins = [
        for (final key in ['originX', 'originY', 'originWidth', 'originHeight'])
          arguments[key],
      ];
      final outcome = {
        'copied': copied,
        'shareMethods': shared.map((call) => call.method).toList(),
        'shareText': arguments['text'],
        'shareSubject': arguments['subject'],
        'positiveOriginSize':
            origins.length == 4 &&
            origins[2] is num &&
            (origins[2] as num) > 0 &&
            origins[3] is num &&
            (origins[3] as num) > 0,
        'savedRows': preferences.getStringList('reports_v2'),
        'attemptMarker': marker.readAsStringSync(),
        'state': confirmed.state,
        'sr': confirmed.serviceRequestNumber,
        'visibleReceipt': find
            .text('Service Request: SR-SYNTHETIC-20-EXACT')
            .evaluate()
            .length,
      };

      expect(outcome, {
        'copied': [
          {'text': 'SR-SYNTHETIC-20-EXACT'},
        ],
        'shareMethods': ['share'],
        'shareText':
            'MyLA311 illegal-dumping receipt\nService Request: SR-SYNTHETIC-20-EXACT\nStatus: Submitted\nDescription: Synthetic couch beside curb\nCoordinates: 34.050000, -118.240000\nDebris location: Curb\nItem count: 2\nCreated: 10/22/2026 · 9:30 AM PDT (UTC-07:00)',
        'shareSubject': 'MyLA311 Service Request SR-SYNTHETIC-20-EXACT',
        'positiveOriginSize': true,
        'savedRows': rows,
        'attemptMarker': markerText,
        'state': ReportState.submitted,
        'sr': 'SR-SYNTHETIC-20-EXACT',
        'visibleReceipt': 1,
      });
    },
  );

  testWidgets('native action failures leave the confirmed receipt unchanged', (
    tester,
  ) async {
    final confirmed = _report(ReportState.submitted, 'SR-SYNTHETIC-20-EXACT');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'synthetic-copy-failure');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_shareChannel, (call) async {
      throw PlatformException(code: 'synthetic-share-failure');
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(_shareChannel, null);
    });
    final outcomes = <String, Object?>{};

    await tester.pumpWidget(
      MaterialApp(home: ReportDetailPage(store: testStore,report: confirmed)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy number'));
    await tester.pumpAndSettle();
    outcomes['copyFailure'] = find
        .text('Could not copy the Service Request number. Please try again.')
        .evaluate()
        .length;
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share receipt'));
    await tester.pumpAndSettle();
    outcomes['shareFailure'] = find
        .text('Receipt could not be shared. Please try again.')
        .evaluate()
        .length;
    outcomes['state'] = confirmed.state;
    outcomes['sr'] = confirmed.serviceRequestNumber;

    expect(outcomes, {
      'copyFailure': 1,
      'shareFailure': 1,
      'state': ReportState.submitted,
      'sr': 'SR-SYNTHETIC-20-EXACT',
    });
  });

  testWidgets(
    'unconfirmed and missing-number records have no successful receipt actions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final records = [
        for (final state in [
          ReportState.notSent,
          ReportState.failed,
          ReportState.submissionUncertain,
        ])
          _report(state, 'SR-SYNTHETIC-UNCONFIRMED'),
        _report(ReportState.submitted, null),
        _report(ReportState.submitted, ''),
      ];
      final outcomes = <List<int>>[];

      for (var index = 0; index < records.length; index++) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(index),
            home: ReportDetailPage(store: testStore,report: records[index]),
          ),
        );
        await tester.pumpAndSettle();
        outcomes.add([
          find.text('Copy number').evaluate().length,
          find.text('Share receipt').evaluate().length,
        ]);
      }

      expect(outcomes, [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
      ]);
    },
  );
}

Report _report(ReportState state, String? number) => Report(
  createdAt: DateTime.utc(2026, 10, 22, 16, 30),
  description: 'Synthetic couch beside curb',
  latitude: 34.05,
  longitude: -118.24,
  debrisLocation: 'Curb',
  quantity: 2,
  state: state,
  serviceRequestNumber: number,
);

class _ReceiptPaths extends PathProviderPlatform {
  _ReceiptPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}
