import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reports/features/dev_api/dev_api_engine.dart';

const testStore = LocalReportStore();

void main() {
  test('a City write action is blocked before any HTTP request', () async {
    var calls = 0;
    final engine = DevApiEngine(
      store: testStore,
      client: MockClient((request) async {
        calls++;
        return http.Response('should never be dispatched', 200);
      }),
    );
    await expectLater(
      engine.run(
        DevApiRequest(
          method: 'POST',
          url: 'https://myla311.lacity.gov/s/sfsites/aura',
          bodyText: _body('submitCase'),
        ),
      ),
      throwsA(
        isA<DevApiException>().having((error) => error.kind, 'kind', 'blocked'),
      ),
    );
    expect(calls, 0);
  });
  test(
    'mixed batches, unknown actions and query overrides never reach HTTP',
    () async {
      var calls = 0;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          calls++;
          return http.Response('', 200);
        }),
      );
      addTearDown(engine.dispose);
      final safe =
          jsonDecode(
                Uri.splitQueryString(_body('fetchCaseTypeDetails'))['message']!,
              )
              as Map<String, Object?>;
      final unsafe =
          jsonDecode(Uri.splitQueryString(_body('createSR'))['message']!)
              as Map<String, Object?>;
      final mixed = Uri(
        queryParameters: {
          ...Uri.splitQueryString(_body('fetchCaseTypeDetails')),
          'message': jsonEncode({
            'actions': [
              ...safe['actions']! as List,
              ...unsafe['actions']! as List,
            ],
          }),
        },
      ).query;
      for (final request in [
        DevApiRequest(method: 'POST', url: _aura, bodyText: mixed),
        DevApiRequest(
          method: 'POST',
          url: _aura,
          bodyText: _body('unknownAction'),
        ),
        DevApiRequest(
          method: 'POST',
          url: '$_aura?message=submitCase',
          bodyText: _body('fetchCaseTypeDetails'),
        ),
        const DevApiRequest(
          method: 'GET',
          url: 'https://myla311.lacity.gov/s/?action=createSR',
        ),
        const DevApiRequest(method: 'DELETE', url: _bootstrap),
        const DevApiRequest(method: 'GET', url: 'http://myla311.lacity.gov/s/'),
        const DevApiRequest(method: 'GET', url: 'https://example.test/s/'),
      ]) {
        await expectLater(engine.run(request), _fails('blocked'));
      }
      expect(calls, 0);
    },
  );

  test(
    'previewing presets is inert and GET and HEAD omit editor bodies',
    () async {
      final requests = <http.Request>[];
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          requests.add(request);
          expect(request.followRedirects, false);
          return http.Response(
            'plain response',
            403,
            headers: {'x-inspector': 'actual'},
          );
        }),
      );
      addTearDown(engine.dispose);
      for (final operation in DevApiOperation.values) {
        expect(operation.label, isNotEmpty);
        expect(operation.detail, isNotEmpty);
        expect(
          engine.preset(operation).url,
          startsWith('https://myla311.lacity.gov/'),
        );
      }
      expect(requests, isEmpty);
      for (final method in ['get', 'HEAD']) {
        final result = await engine.run(
          DevApiRequest(
            method: method,
            url: _bootstrap,
            headersText: '{"Accept":"text/html"}',
            bodyText: 'submitCase should not be a GET body',
          ),
        );
        expect(result.statusCode, 403);
        expect(result.headers['x-inspector'], 'actual');
        expect(result.body, 'plain response');
        expect(result.formattedBody, 'plain response');
        expect(result.elapsed, greaterThanOrEqualTo(Duration.zero));
      }
      expect(requests.map((request) => request.body), ['', '']);
      expect(() => requests.first.headers, returnsNormally);
    },
  );

  test(
    'manual bootstrap and all Aura read presets use the captured contract',
    () async {
      final requests = <http.Request>[];
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(Uri.encodeComponent(_shell), 200);
          }
          final fields = Uri.splitQueryString(request.body);
          expect(
            request.headers['content-type'],
            contains('application/x-www-form-urlencoded'),
          );
          expect(fields['aura.token'], 'null');
          expect(jsonDecode(fields['aura.context']!)['fwuid'], 'fixture-fwuid');
          final action =
              (jsonDecode(fields['message']!)['actions'] as List).single;
          if (action['params']['method'] == 'fetchInitialDetails') {
            return http.Response(
              _reply({
                'caseConfigurationList': [
                  {
                    'caseConfigurations': [
                      {
                        'uxType': 'Illegal Dumping Item Pickup',
                        'caseConfigId': 'type%2Ffixture',
                      },
                    ],
                  },
                ],
              }),
              200,
            );
          }
          if (action['params']['method'] == 'validateAddress') {
            return http.Response(
              _reply({
                'address': {'X': -118.24, 'Y': 34.05},
              }),
              200,
            );
          }
          return http.Response('{"read":true}', 200);
        }),
      );
      addTearDown(engine.dispose);
      await engine.run(engine.preset(DevApiOperation.bootstrap));
      await engine.run(engine.preset(DevApiOperation.requestTypes));
      final config = engine.preset(DevApiOperation.caseTypeDetails);
      final configFields = Uri.splitQueryString(config.bodyText);
      expect(configFields['aura.pageURI'], contains('type%2Ffixture'));
      expect(
        jsonDecode(
          configFields['message']!,
        )['actions'][0]['params']['params']['caseTypeId'],
        'type/fixture',
      );
      await engine.run(config);
      for (final operation in [
        DevApiOperation.validateAddress,
        DevApiOperation.nearby,
      ]) {
        final response = await engine.run(
          engine.preset(
            operation,
            arguments: {'latitude': 34.05, 'longitude': -118.24},
          ),
        );
        expect(response.statusCode, 200);
      }
      expect(requests, hasLength(5));
      expect(requests.last.url.queryParameters['r'], '4');
    },
  );

  test(
    'malformed remote context and JSON retain the actual response',
    () async {
      var reads = 0;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          if (request.method == 'GET') return http.Response('$_shell%FF', 200);
          reads++;
          return http.Response(
            reads == 1
                ? _reply({
                    'popularCaseList': [
                      {
                        'uxType': 'Illegal Dumping Item Pickup',
                        'caseConfigId': 'popular-type',
                      },
                    ],
                  })
                : 'actual invalid JSON response',
            200,
          );
        }),
      );
      addTearDown(engine.dispose);
      final bootstrap = await engine.run(
        engine.preset(DevApiOperation.bootstrap),
      );
      expect(bootstrap.body, endsWith('%FF'));
      await engine.run(engine.preset(DevApiOperation.requestTypes));
      final config = Uri.splitQueryString(
        engine.preset(DevApiOperation.caseTypeDetails).bodyText,
      );
      expect(
        jsonDecode(
          config['message']!,
        )['actions'][0]['params']['params']['caseTypeId'],
        'popular-type',
      );
      final malformed = await engine.run(
        engine.preset(DevApiOperation.requestTypes),
      );
      expect(malformed.statusCode, 200);
      expect(malformed.body, 'actual invalid JSON response');
    },
  );

  test(
    'invalid prerequisites, forms, argument values and headers stay local',
    () async {
      var calls = 0;
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient((request) async {
          calls++;
          return http.Response(_shell, 200);
        }),
      );
      addTearDown(engine.dispose);
      await expectLater(
        engine.run(engine.preset(DevApiOperation.requestTypes)),
        _fails('invalid'),
      );
      await expectLater(
        engine.run(
          const DevApiRequest(
            method: 'POST',
            url: _aura,
            bodyText: 'message=bad',
          ),
        ),
        _fails('invalid'),
      );
      await expectLater(
        engine.run(
          DevApiRequest(
            method: 'POST',
            url: _aura,
            bodyText: '${_body('fetchCaseTypeDetails')}&message=duplicate',
          ),
        ),
        _fails('invalid'),
      );
      for (final headers in ['not json', '{"header":42}']) {
        await expectLater(
          engine.run(
            DevApiRequest(method: 'GET', url: _bootstrap, headersText: headers),
          ),
          _fails('invalid'),
        );
      }
      expect(calls, 0);
      await engine.run(engine.preset(DevApiOperation.bootstrap));
      await expectLater(
        engine.run(engine.preset(DevApiOperation.caseTypeDetails)),
        _fails('invalid'),
      );
      await expectLater(
        engine.run(
          engine.preset(
            DevApiOperation.validateAddress,
            arguments: {'latitude': 91, 'longitude': 0},
          ),
        ),
        _fails('invalid'),
      );
      await expectLater(
        engine.run(engine.preset(DevApiOperation.nearby)),
        _fails('invalid'),
      );
      expect(calls, 1);
    },
  );

  test(
    'cancel aborts the transport, settles promptly and ignores a late response',
    () async {
      final client = _PendingClient();
      final engine = DevApiEngine(store: testStore, client: client);
      final result = engine.run(engine.preset(DevApiOperation.bootstrap));
      await expectLater(
        engine.run(engine.preset(DevApiOperation.bootstrap)),
        _fails('busy'),
      );
      final failure = expectLater(result, _fails('cancelled'));
      engine.cancel();
      await failure;
      await (client.requests.single as http.AbortableRequest).abortTrigger;
      client.pending.complete(
        http.StreamedResponse(Stream.value(utf8.encode(_shell)), 200),
      );
      await Future<void>(() {});
      final context = jsonDecode(
        Uri.splitQueryString(
          engine.preset(DevApiOperation.requestTypes).bodyText,
        )['aura.context']!,
      );
      expect(context['fwuid'], '');
      engine.cancel();
      engine.dispose();
      expect(client.closed, false);
      await expectLater(
        engine.run(engine.preset(DevApiOperation.bootstrap)),
        _fails('disposed'),
      );
    },
  );

  test('timeout aborts without waiting for a late server result', () async {
    final client = _PendingClient();
    final engine = DevApiEngine(
      store: testStore,
      client: client,
      timeout: const Duration(milliseconds: 5),
    );
    await expectLater(
      engine.run(engine.preset(DevApiOperation.bootstrap)),
      _fails('timeout'),
    );
    await (client.requests.single as http.AbortableRequest).abortTrigger;
    client.pending.completeError(http.ClientException('aborted'));
    await Future<void>(() {});
    engine.dispose();
  });

  test(
    'network errors differ from HTTP responses and owned clients dispose',
    () async {
      final engine = DevApiEngine(
        store: testStore,
        client: MockClient(
          (request) async => throw http.ClientException('offline'),
        ),
      );
      await expectLater(
        engine.run(engine.preset(DevApiOperation.bootstrap)),
        _fails('network'),
      );
      engine.dispose();
      DevApiEngine(store: testStore).dispose();
      final response = DevApiResponse(
        statusCode: 204,
        headers: {},
        body: '',
        elapsed: Duration.zero,
      );
      expect(response.formattedBody, '(Empty response body)');
      expect(() => response.headers['new'] = 'value', throwsUnsupportedError);
      expect(
        const DevApiException('actual error', 'network').toString(),
        'actual error',
      );
    },
  );
}

String _body(String method) => Uri(
  queryParameters: {
    'message': jsonEncode({
      'actions': [
        {
          'descriptor': r'aura://ApexActionController/ACTION$execute',
          'params': {
            'namespace': '',
            'classname': 'X11_RI_ParentController',
            'method': method,
            'params': <String, Object?>{},
            'cacheable': false,
            'isContinuation': false,
          },
        },
      ],
    }),
    'aura.context': '{}',
    'aura.pageURI': '/s/',
    'aura.token': 'null',
  },
).query;

const _bootstrap = 'https://myla311.lacity.gov/s/';
const _aura = 'https://myla311.lacity.gov/s/sfsites/aura';
const _shell =
    '<script>{"fwuid":"fixture-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"fixture-app"}}</script>';

Matcher _fails(String kind) =>
    throwsA(isA<DevApiException>().having((error) => error.kind, 'kind', kind));

String _reply(Object response) => jsonEncode({
  'actions': [
    {
      'state': 'SUCCESS',
      'returnValue': {
        'returnValue': jsonEncode({'isSuccess': true, 'response': response}),
      },
    },
  ],
});

class _PendingClient extends http.BaseClient {
  final pending = Completer<http.StreamedResponse>();
  final requests = <http.BaseRequest>[];
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return pending.future;
  }

  @override
  void close() => closed = true;
}
