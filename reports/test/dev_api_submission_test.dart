import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/dev_api/dev_api_engine.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

void main() {
  test(
    'review sends nothing and confirmation dispatches exactly the reviewed three-photo plan',
    () async {
      final support = await _storage();
      final photos = [
        for (var i = 0; i < 3; i++)
          File('${support.path}/photo-$i.jpg')..writeAsBytesSync([i, 12, 31]),
      ];
      final report = _report(paths: photos.map((file) => file.path).toList());
      final calls = <http.Request>[];
      DevApiSubmitPlan? reviewed;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          calls.add(request);
          if (_method(request) == 'submitCase') {
            final retained = await testStore.loadReports();
            final preview = jsonDecode(reviewed!.preview);
            expect(retained.single.state, ReportState.submissionUncertain);
            expect(retained.single.photoPaths, report.photoPaths);
            expect(request.url.toString(), preview['destination']);
            final params = jsonDecode(
              Uri.splitQueryString(request.body)['message']!,
            )['actions'][0]['params']['params'];
            expect(params, preview['actionParams']);
            expect(request.followRedirects, false);
          }
          return _reply(request);
        }),
      );
      addTearDown(engine.dispose);
      await _reads(engine, report);
      expect(calls, hasLength(4));
      reviewed = await engine.prepareSubmission(report);
      expect(calls, hasLength(4));
      final params = jsonDecode(reviewed.preview)['actionParams'];
      expect(jsonDecode(params['sFileLinks']), hasLength(3));
      expect((await testStore.loadReports()), isEmpty);
      await expectLater(
        engine.confirmSubmission(
          reviewed,
          confirmed: false,
          currentReport: report,
        ),
        throwsA(isA<DevApiException>()),
      );
      expect(calls, hasLength(4));
      final result = await engine.confirmSubmission(
        reviewed,
        confirmed: true,
        currentReport: report,
      );
      expect(
        result,
        isA<SubmissionAccepted>().having(
          (result) => result.serviceRequestNumber,
          'number',
          'SYNTHETIC-SR',
        ),
      );
      expect(calls, hasLength(5));
      final retained = (await testStore.loadReports()).single;
      expect(retained.state, ReportState.submitted);
      expect(retained.photoPaths, report.photoPaths);
      await expectLater(
        engine.confirmSubmission(
          reviewed,
          confirmed: true,
          currentReport: report,
        ),
        throwsA(isA<DevApiException>()),
      );
      expect(calls, hasLength(5));
    },
  );

  test(
    'an existing uncertain attempt cannot be bypassed by a new inspector report',
    () async {
      final support = await _storage();
      final uncertain = _report(state: ReportState.submissionUncertain);
      await testStore.saveReport(uncertain);
      final marker = File('${support.path}/submission-attempt.json');
      final markerBefore = marker.readAsBytesSync();
      final preferences = await SharedPreferences.getInstance();
      final rows = preferences.getStringList('reports_v2');
      var calls = 0;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          calls++;
          return _reply(request);
        }),
      );
      addTearDown(engine.dispose);
      await expectLater(
        engine.prepareSubmission(_report(createdAt: DateTime(2026, 10, 23))),
        throwsA(
          isA<DevApiException>().having(
            (error) => error.kind,
            'kind',
            'blocked',
          ),
        ),
      );
      expect(calls, 0);
      expect(marker.readAsBytesSync(), markerBefore);
      expect(preferences.getStringList('reports_v2'), rows);
    },
  );

  test(
    'coordinate and input changes invalidate the reviewed write without dispatch',
    () async {
      await _storage();
      var calls = 0;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          calls++;
          return _reply(request);
        }),
      );
      addTearDown(engine.dispose);
      final report = _report();
      await expectLater(
        engine.prepareSubmission(report),
        throwsA(isA<DevApiException>()),
      );
      await _reads(engine, report);
      final plan = await engine.prepareSubmission(report);
      await expectLater(
        engine.confirmSubmission(
          plan,
          confirmed: true,
          currentReport: _report(description: 'Edited after review'),
        ),
        throwsA(isA<DevApiException>()),
      );
      engine.invalidate();
      await expectLater(
        engine.confirmSubmission(plan, confirmed: true, currentReport: report),
        throwsA(isA<DevApiException>()),
      );
      await expectLater(
        engine.prepareSubmission(report),
        throwsA(isA<DevApiException>()),
      );
      expect(calls, 4);
    },
  );

  test(
    'bootstrap display and request previews never expose live session values',
    () async {
      await _storage();
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async => _reply(request)),
      );
      addTearDown(engine.dispose);
      final response = await engine.run(
        engine.preset(DevApiOperation.bootstrap),
      );
      expect(response.formattedBody, contains('htmlCharacters'));
      expect(response.formattedBody, isNot(contains('private-fwuid')));
      final encoded = DevApiResponse(
        statusCode: 200,
        headers: const {},
        body: Uri.encodeComponent(response.body),
        elapsed: Duration.zero,
        requestUrl: 'https://myla311.lacity.gov/s/',
      );
      expect(encoded.formattedBody, contains('htmlCharacters'));
      expect(encoded.formattedBody, isNot(contains('private-fwuid')));
      final preview = engine.preview(
        engine.preset(DevApiOperation.requestTypes),
      );
      expect(preview, isNot(contains('private-fwuid')));
      expect(preview, isNot(contains('private-app')));
    },
  );
  test(
    'JSON response redaction preserves errors and bootstrap preview is inert',
    () {
      final response = DevApiResponse(
        statusCode: 403,
        headers: {},
        body:
            '{"errors":[{"message":"Denied","token":"private"}],"fwuid":"secret"}',
        elapsed: Duration.zero,
      );
      expect(response.formattedBody, contains('Denied'));
      expect(response.formattedBody, isNot(contains('private')));
      expect(response.formattedBody, isNot(contains('secret')));
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async => _reply(request)),
      );
      addTearDown(engine.dispose);
      expect(
        engine.preview(engine.preset(DevApiOperation.bootstrap)),
        contains('GET'),
      );
    },
  );

  test(
    'submitted saved identity blocks review and rejected confirmation restores its draft',
    () async {
      await _storage();
      final report = _report();
      await testStore.saveReport(report.submittedWith('EXISTING-SR'));
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          if (_method(request) == 'submitCase') {
            return http.Response(
              jsonEncode({
                'actions': [
                  {
                    'state': 'SUCCESS',
                    'returnValue': {
                      'returnValue': jsonEncode({
                        'isSuccess': false,
                        'message': 'Synthetic rejection',
                      }),
                    },
                  },
                ],
              }),
              200,
            );
          }
          return _reply(request);
        }),
      );
      addTearDown(engine.dispose);
      await expectLater(
        engine.prepareSubmission(report),
        throwsA(isA<DevApiException>()),
      );
      await testStore.replaceReport(
        (await testStore.loadReports()).single,
        report,
      );
      await _reads(engine, report);
      final plan = await engine.prepareSubmission(report);
      final result = await engine.confirmSubmission(
        plan,
        confirmed: true,
        currentReport: report,
      );
      expect(result, isA<SubmissionFailed>());
      expect(
        (result as SubmissionFailed).kind,
        isNot(SubmissionFailureKind.uncertain),
      );
      expect((await testStore.loadReports()).single.state, ReportState.notSent);
    },
  );

  test(
    'cancel after dispatch preserves the durable uncertainty marker',
    () async {
      await _storage();
      final started = Completer<void>();
      final release = Completer<http.Response>();
      final report = _report();
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          if (_method(request) == 'submitCase') {
            started.complete();
            return release.future;
          }
          return _reply(request);
        }),
      );
      addTearDown(engine.dispose);
      await _reads(engine, report);
      final plan = await engine.prepareSubmission(report);
      final pending = engine.confirmSubmission(
        plan,
        confirmed: true,
        currentReport: report,
      );
      await started.future;
      engine.cancel();
      expect(
        (await pending as SubmissionFailed).kind,
        SubmissionFailureKind.uncertain,
      );
      expect(
        (await testStore.loadReports()).single.state,
        ReportState.submissionUncertain,
      );
      release.complete(http.Response('Unconfirmed', 500));
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('timeout after dispatch retains uncertainty without retrying', () async {
    await _storage();
    var submits = 0;
    final release = Completer<http.Response>();
    final report = _report();
    final engine = DevApiEngine(
      store: testStore,
      timeout: const Duration(milliseconds: 30),
      client: MockClient((request) async {
        if (_method(request) == 'submitCase') {
          submits++;
          return release.future;
        }
        return _reply(request);
      }),
    );
    addTearDown(engine.dispose);
    await _reads(engine, report);
    final plan = await engine.prepareSubmission(report);
    expect(
      (await engine.confirmSubmission(
                plan,
                confirmed: true,
                currentReport: report,
              )
              as SubmissionFailed)
          .kind,
      SubmissionFailureKind.uncertain,
    );
    expect(submits, 1);
    expect(
      (await testStore.loadReports()).single.state,
      ReportState.submissionUncertain,
    );
    release.complete(http.Response('Unconfirmed', 500));
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'default prepared client closes after an offline dispatch failure',
    () async {
      final offline = _OfflineHttpClient();
      await HttpOverrides.runZoned(() async {
        final client = PortalSubmissionClient();
        final plan = await client.prepareInspectorSubmission(
          _report(),
          fwuid: 'private',
          appId: 'private',
          caseTypeId: 'fixture',
          requestCount: 0,
          config: const {},
          contact: const {},
          address: const {},
          addressStatus: 'Locator Success',
        );
        expect(await client.sendPrepared(plan), isA<SubmissionFailed>());
        expect(offline.closed, true);
      }, createHttpClient: (_) => offline);
    },
  );

  test(
    'prepared Portal plans reject invalid data and cannot cross client ownership',
    () async {
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async => _reply(request)),
      );
      final other = PortalSubmissionClient(
        httpClient: MockClient(
          (request) async => throw StateError('No dispatch'),
        ),
      );
      Future<PortalPreparedSubmission> prepare(Report report) =>
          client.prepareInspectorSubmission(
            report,
            fwuid: 'private',
            appId: 'private',
            caseTypeId: 'fixture',
            requestCount: 0,
            config: const {'sCaseType': 'Illegal Dumping Item Pickup'},
            contact: const {},
            address: const {},
            addressStatus: 'Locator Success',
          );
      await expectLater(
        prepare(_report(description: 'x' * 751)),
        throwsFormatException,
      );
      final plan = await prepare(_report());
      expect(await other.sendPrepared(plan), isA<SubmissionFailed>());
      expect(await client.sendPrepared(plan), isA<SubmissionAccepted>());
      expect(await client.sendPrepared(plan), isA<SubmissionFailed>());
    },
  );
  test(
    'changing operation preserves validated locator but report edits clear it',
    () async {
      await _storage();
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async => _reply(request)),
      );
      addTearDown(engine.dispose);
      await _reads(engine, _report());
      engine.invalidate(clearLocation: false);
      final nearby = engine.preset(
        DevApiOperation.nearby,
        arguments: {'latitude': 34.05, 'longitude': -118.24},
      );
      expect(engine.preview(nearby), contains('-118.24'));
      expect((await engine.run(nearby)).statusCode, 200);
      engine.invalidate();
      await expectLater(
        engine.run(
          engine.preset(
            DevApiOperation.nearby,
            arguments: {'latitude': 34.05, 'longitude': -118.24},
          ),
        ),
        throwsA(isA<DevApiException>()),
      );
    },
  );
}

Future<Directory> _storage() async {
  SharedPreferences.setMockInitialValues({});
  final previous = PathProviderPlatform.instance;
  final support = Directory.systemTemp.createTempSync('inspector-submit-');
  PathProviderPlatform.instance = _SupportPath(support.path);
  addTearDown(() async {
    PathProviderPlatform.instance = previous;
    await support.delete(recursive: true);
  });
  return support;
}

Report _report({
  List<String> paths = const [],
  ReportState state = ReportState.notSent,
  DateTime? createdAt,
  String description = 'SYNTHETIC couch',
}) => Report(
  description: description,
  latitude: 34.05,
  longitude: -118.24,
  createdAt: createdAt ?? DateTime(2026, 10, 22),
  photoPaths: paths,
  debrisLocation: 'Curb',
  quantity: 2,
  state: state,
);

Future<void> _reads(DevApiEngine engine, Report report) async {
  for (final operation in [
    DevApiOperation.bootstrap,
    DevApiOperation.requestTypes,
    DevApiOperation.caseTypeDetails,
    DevApiOperation.validateAddress,
  ]) {
    await engine.run(
      engine.preset(
        operation,
        arguments: {'latitude': report.latitude, 'longitude': report.longitude},
      ),
    );
  }
}

String? _method(http.Request request) => request.method == 'GET'
    ? null
    : jsonDecode(
            Uri.splitQueryString(request.body)['message']!,
          )['actions'][0]['params']['method']
          as String?;

http.Response _reply(http.Request request) {
  if (request.method == 'GET') {
    return http.Response(
      '<script>{"fwuid":"private-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"private-app"}}</script>',
      200,
    );
  }
  final response = switch (_method(request)) {
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
    _ => null,
  };
  return http.Response(
    jsonEncode({
      'actions': [
        {
          'state': 'SUCCESS',
          'returnValue': {
            'returnValue': jsonEncode({
              'isSuccess': true,
              'message': 'Locator Success',
              'response': response,
            }),
          },
        },
      ],
    }),
    200,
  );
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}

class _OfflineHttpClient implements HttpClient {
  bool closed = false;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      throw const SocketException('Offline fixture');
  @override
  void close({bool force = false}) {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
