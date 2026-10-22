import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/dev_api/presentation/dev_api_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/design/reports_design.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final previous = PathProviderPlatform.instance;
    final support = Directory.systemTemp.createTempSync('dev-sheet-');
    PathProviderPlatform.instance = _SupportPath(support.path);
    addTearDown(() async {
      PathProviderPlatform.instance = previous;
      await support.delete(recursive: true);
    });
  });

  testWidgets(
    'Home and Help open the same near-full-height sheet with fixed controls',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(const ReportApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dev / API'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Dev / API mode'), findsOneWidget);
      expect(find.text('REPORTS · MYLA311'), findsOneWidget);
      final header = tester.getRect(find.byKey(const Key('dev-api-header')));
      final footer = tester.getRect(find.byKey(const Key('dev-api-footer')));
      expect(header.top, greaterThan(0));
      expect(header.top, lessThan(100));
      expect(footer.bottom, lessThanOrEqualTo(844));
      await _show(tester, find.text('Request history'));
      expect(tester.getRect(find.byKey(const Key('dev-api-header'))), header);
      expect(tester.getRect(find.byKey(const Key('dev-api-footer'))), footer);
      await tester.tap(find.byTooltip('Close Dev API mode'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await tester.ensureVisible(find.text('Help and information'));
      await tester.tap(find.text('Help and information'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Dev / API')).bottom,
        lessThan(tester.getRect(find.text('Help')).top),
      );
      await tester.tap(find.text('Dev / API'));
      await tester.pumpAndSettle();
      expect(find.text('Dev / API mode'), findsOneWidget);
      await tester.tap(find.byTooltip('Close Dev API mode'));
      await tester.pumpAndSettle();
      expect(find.text('Help'), findsOneWidget);
    },
  );

  testWidgets(
    'opening editing and previewing are local and preserve the saved draft',
    (tester) async {
      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 22),
        description: 'Saved report',
        latitude: 34.05,
        longitude: -118.24,
        debrisLocation: 'Alley',
        quantity: '2',
      );
      await testStore.saveDraft(draft);
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);
      await _open(tester, client);
      await _show(tester, find.byKey(const Key('dev-api-report')));
      await _until(
        tester,
        () => tester
            .widget<TextField>(find.byKey(const Key('dev-api-report')))
            .controller!
            .text
            .contains('Saved report'),
      );
      await tester.enterText(
        find.byKey(const Key('dev-api-report')),
        '{"report":{"description":"Inspector only","latitude":34.05}}',
      );
      await _show(tester, find.text('Preview arguments'));
      await tester.tap(find.text('Preview arguments'));
      await tester.pumpAndSettle();
      expect(
        find.text('Arguments previewed locally. No request sent.'),
        findsOneWidget,
      );

      expect(requests, 0);
      final retained = await tester.runAsync(testStore.loadDraft);
      expect(retained?.toJson(), draft.toJson());
    },
  );

  testWidgets('named operation selection and argument preview never dispatch', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    await _open(tester, client);
    expect(find.byKey(const Key('dev-api-url')), findsNothing);
    expect(find.byKey(const Key('dev-api-headers')), findsNothing);
    expect(find.byKey(const Key('dev-api-body')), findsNothing);
    await _operation(tester, 'Validate report coordinates');
    await _show(tester, find.byKey(const Key('dev-api-report')));
    await tester.enterText(
      find.byKey(const Key('dev-api-report')),
      '{"report":{"latitude":34.05,"longitude":-118.24}}',
    );
    await _show(tester, find.text('Preview arguments'));
    await tester.tap(find.text('Preview arguments'));
    await tester.pumpAndSettle();
    expect(
      find.text('Arguments previewed locally. No request sent.'),
      findsOneWidget,
    );
    expect(requests, 0);
  });

  testWidgets(
    'Run 311 request alone dispatches bootstrap and records received status',
    (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('<html>Synthetic bootstrap</html>', 200);
      });
      addTearDown(client.close);
      await _open(tester, client);
      expect(requests, isEmpty);
      await tester.tap(find.text('Run 311 request'));
      await _until(
        tester,
        () =>
            requests.isNotEmpty &&
            find.textContaining('HTTP 200.').evaluate().isNotEmpty,
      );
      expect(requests.single.method, 'GET');
      expect(requests.single.url.toString(), 'https://myla311.lacity.gov/s/');
      expect(requests.single.body, isEmpty);
      await _show(tester, find.text('Request history'));
      expect(find.textContaining('HTTP 200'), findsWidgets);
    },
  );

  testWidgets('cancel is pinned and ignores a late response', (tester) async {
    final pending = Completer<http.Response>();
    final client = MockClient((_) => pending.future);
    addTearDown(client.close);
    await _open(tester, client);
    await tester.tap(find.text('Run 311 request'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Running…'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel request'));
    await tester.pump();
    pending.complete(http.Response('Late response', 200));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Cancelled locally. The server may already have received the request.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Late response'), findsNothing);
  });

  testWidgets('invalid and nested-invalid report JSON block locally', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    await _open(tester, client);
    for (final json in ['[]', '{"report":[]}']) {
      await _show(tester, find.byKey(const Key('dev-api-report')));
      await tester.enterText(find.byKey(const Key('dev-api-report')), json);
      await _show(tester, find.text('Preview arguments'));
      await tester.tap(find.text('Preview arguments'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot preview arguments:'), findsOneWidget);
      await tester.tap(find.text('Run 311 request'));
      await tester.pumpAndSettle();
      expect(find.textContaining('must be a JSON object.'), findsOneWidget);
      await _show(tester, find.text('Review submitCase payload'));
      await tester.tap(find.text('Review submitCase payload'));
      await tester.pumpAndSettle();
      expect(find.textContaining('must be a JSON object.'), findsOneWidget);
    }
    expect(requests, 0);
  });

  for (final accepted in [true, false]) {
    testWidgets(
      'submit review is local and checkbox confirms actual outcome $accepted',
      (tester) async {
        await testStore.saveDraft(
          ReportDraft(
            createdAt: DateTime(2026, 10, 22),
            description: 'Synthetic fixture only',
            latitude: 34.05,
            longitude: -118.24,
            debrisLocation: 'Alley',
            quantity: '2',
          ),
        );
        final methods = <String>[];
        final client = MockClient((request) async {
          if (request.method == 'GET') {
            methods.add('bootstrap');
            return http.Response(
              '"fwuid":"fixture-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"fixture-app"}',
              200,
            );
          }
          final fields = Uri.splitQueryString(request.body);
          final action =
              (jsonDecode(fields['message']!)
                      as Map<String, dynamic>)['actions'][0]['params']['method']
                  as String;
          methods.add(action);
          if (action == 'submitCase' && !accepted) {
            return http.Response(
              _reply({}, message: 'Synthetic rejection', isSuccess: false),
              200,
            );
          }
          final Object response = switch (action) {
            'fetchInitialDetails' => {
              'popularCaseList': [
                {
                  'uxType': 'Illegal Dumping Item Pickup',
                  'caseConfigId': 'fixture-type',
                },
              ],
            },
            'fetchCaseTypeDetails' => {
              'objCaseConfigWrapper': {
                'sCaseType': 'Illegal Dumping Item Pickup',
                'sCasePriority': 'Normal',
                'sCaseDefaultStatus': 'New',
                'lstCaseQuestion': [
                  for (final field in [
                    'Description',
                    'Location_of_Loose_Miscellaneous_Debris__c',
                    'No_of_Loose_Miscellaneous_Debris__c',
                  ])
                    {'sFieldtoUpdate': field, 'iOrder': 1},
                ],
              },
              'contactWrapperResponse': {'bIsLogin': false},
            },
            'validateAddress' => jsonEncode({
              'address': {
                'ShortLabel': 'SYNTHETIC CURB',
                'City': 'LOS ANGELES',
                'X': -118.24,
                'Y': 34.05,
              },
            }),
            'submitCase' => {'sCaseNumber': 'SYNTHETIC-SR'},
            _ => throw StateError('Unexpected synthetic operation $action'),
          };
          return http.Response(
            _reply(
              response,
              message: action == 'validateAddress' ? 'Locator Success' : '',
            ),
            200,
          );
        });
        addTearDown(client.close);
        await _open(tester, client);
        await _show(tester, find.byKey(const Key('dev-api-report')));
        await _until(
          tester,
          () => tester
              .widget<TextField>(find.byKey(const Key('dev-api-report')))
              .controller!
              .text
              .contains('Synthetic fixture only'),
        );
        for (final label in [
          'Guest bootstrap',
          'Find Illegal Dumping Item Pickup',
          'Load request form questions',
          'Validate report coordinates',
        ]) {
          await _operation(tester, label);
          final count = methods.length;
          await tester.tap(find.text('Run 311 request'));
          await _until(
            tester,
            () =>
                methods.length > count &&
                find.textContaining('HTTP 200.').evaluate().isNotEmpty,
          );
        }
        final reads = List<String>.of(methods);
        await _show(tester, find.text('Review submitCase payload'));
        await tester.tap(find.text('Review submitCase payload'));
        await _until(
          tester,
          () => find.byType(AlertDialog).evaluate().isNotEmpty,
        );
        expect(methods, reads);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirm real submission'),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Keep reviewing'));
        await tester.pumpAndSettle();
        expect(methods, reads);
        await tester.tap(find.text('Review submitCase payload'));
        await _until(
          tester,
          () => find.byType(AlertDialog).evaluate().isNotEmpty,
        );
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.tap(find.text('Confirm real submission'));
        await _until(
          tester,
          () => find
              .text(
                accepted
                    ? 'City accepted Service Request SYNTHETIC-SR.'
                    : 'The Portal did not confirm whether the report was received. Do not submit it again.',
              )
              .evaluate()
              .isNotEmpty,
        );
        expect(methods.where((method) => method == 'submitCase'), hasLength(1));
      },
    );
  }

  testWidgets('empty storage yields an empty isolated report snapshot', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('{}', 200));
    addTearDown(client.close);
    await _open(tester, client);
    await _show(tester, find.text('Current Report data'));
    await _until(
      tester,
      () => find.text('No saved report').evaluate().isNotEmpty,
    );
    await _show(tester, find.byKey(const Key('dev-api-report')));
    expect(
      jsonDecode(
        tester
            .widget<TextField>(find.byKey(const Key('dev-api-report')))
            .controller!
            .text,
      ),
      {'report': {}},
    );
  });

  testWidgets(
    'latest saved report is snapshotted without changing saved rows',
    (tester) async {
      final older = Report(
        description: 'Older report',
        latitude: 34,
        longitude: -118,
        createdAt: DateTime(2026, 1, 1),
      );
      final newer = Report(
        description: 'Newest report',
        latitude: 35,
        longitude: -119,
        createdAt: DateTime(2026, 2, 1),
      );
      final rows = [jsonEncode(older.toJson()), jsonEncode(newer.toJson())];
      SharedPreferences.setMockInitialValues({'reports_v2': rows});
      final client = MockClient((_) async => http.Response('{}', 200));
      addTearDown(client.close);
      await _open(tester, client);
      await _show(tester, find.byKey(const Key('dev-api-report')));
      await _until(
        tester,
        () => tester
            .widget<TextField>(find.byKey(const Key('dev-api-report')))
            .controller!
            .text
            .contains('Newest report'),
      );
      await _show(tester, find.text('Latest saved report'));
      expect(find.text('Latest saved report'), findsOneWidget);
      final saved = await SharedPreferences.getInstance();
      expect(saved.getStringList('reports_v2'), rows);
    },
  );

  testWidgets('unreadable saved draft is reported without discarding it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'report_draft_v1': '{broken'});
    final client = MockClient((_) async => http.Response('{}', 200));
    addTearDown(client.close);
    await _open(tester, client);
    await _show(tester, find.text('Current Report data'));
    await _until(
      tester,
      () => find.text('Saved data unavailable').evaluate().isNotEmpty,
    );
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('report_draft_v1'), '{broken');
  });

  testWidgets(
    'history retains twelve metadata events and edits clear stale results',
    (tester) async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('<html>Synthetic</html>', 200);
      });
      addTearDown(client.close);
      await _open(tester, client);
      for (var index = 0; index < 13; index++) {
        await tester.tap(find.text('Run 311 request'));
        await _until(
          tester,
          () =>
              requests == index + 1 &&
              find.textContaining('HTTP 200.').evaluate().isNotEmpty,
        );
      }
      await _show(tester, find.text('Request history'));
      expect(find.textContaining(' · HTTP 200 · '), findsNWidgets(12));
      await _show(tester, find.byKey(const Key('dev-api-report')));
      await tester.enterText(
        find.byKey(const Key('dev-api-report')),
        '{"report":{}}',
      );
      await _show(
        tester,
        find.text('Previous result cleared after an input change.'),
      );
      expect(
        find.text('Previous result cleared after an input change.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sheet remains usable at narrow width and double text without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = MockClient((_) async => http.Response('{}', 200));
      addTearDown(client.close);
      await _open(tester, client, textScale: 2, disableAnimations: true);
      await _show(tester, find.text('Current Report data'));
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Run 311 request')).bottom,
        lessThanOrEqualTo(640),
      );
    },
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester,
  http.Client client, {
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ReportsStyle.theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showDevApiSheet(context, store: testStore, httpClient: client),
            child: const Text('Open workspace'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open workspace'));
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('dev-api-scroll')),
        matching: find.byType(Scrollable),
      )
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(finder, 220, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> _operation(WidgetTester tester, String label) async {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byKey(const Key('dev-api-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  scrollable.position.jumpTo(0);
  await tester.pumpAndSettle();
  await _show(tester, find.byKey(const Key('dev-api-operation')));
  await tester.tap(find.byKey(const Key('dev-api-operation')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 1000 && !ready(); i++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  expect(
    ready(),
    isTrue,
    reason: tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('dev-api-footer')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .join(' | '),
  );
  await tester.pumpAndSettle();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

String _reply(Object response, {String message = '', bool isSuccess = true}) =>
    jsonEncode({
      'actions': [
        {
          'state': 'SUCCESS',
          'returnValue': {
            'returnValue': jsonEncode({
              'isSuccess': isSuccess,
              'response': response,
              'message': message,
            }),
          },
        },
      ],
    });
