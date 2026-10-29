import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/illegal_dumping_catalog.dart';

const _homePage =
    '<html><head><script>window.Aura = {"mode":"PROD","fwuid":"fixture-fwuid",'
    '"loaded":{"APPLICATION@markup://siteforce:communityApp":"1893_fixture-app"}};'
    '</script></head><body></body></html>';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Report _report({
  String? photoPath,
  List<String>? photoPaths,
  String? debrisLocation = 'Curb',
  int? quantity = 3,
  String description = 'Mattress and boxes at the curb.',
}) => Report(
  description: description,
  latitude: 34.054047,
  longitude: -118.24317,
  createdAt: DateTime.utc(2026, 10, 21),
  photoPath: photoPath,
  photoPaths: photoPaths,
  debrisLocation: debrisLocation,
  quantity: quantity,
);

Map<String, Object?> _envelope({
  required bool isSuccess,
  String message = 'Success',
  Object? response,
}) => {
  'toastPayload': null,
  'response': response,
  'message': message,
  'isSuccess': isSuccess,
  'isHTML': null,
  'errorLogs': null,
  'ccbCheck': null,
};

http.Response _auraReply(Map<String, Object?> envelope) => http.Response(
  jsonEncode({
    'actions': [
      {
        'id': '1;a',
        'state': 'SUCCESS',
        'returnValue': {
          'returnValue': jsonEncode(envelope),
          'cacheable': false,
        },
        'error': <Object>[],
      },
    ],
    'context': {'ignore': true},
  }),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _cityHallAddress() => {
  'ShortLabel': '200 N SPRING ST',
  'LongLabel': '200 N SPRING ST, LOS ANGELES, CA, 90012',
  'City': 'LOS ANGELES',
  'Postal': '90012',
  'X': -118.24317,
  'Y': 34.054047,
  'Addr_type': 'PointAddress',
  'SRCouncilDistrictNo': 14,
};

Map<String, Object?> _question(
  String? field,
  num order,
  String type, {
  String answer = '',
  bool display = false,
}) => {
  'sFieldtoUpdate': field,
  'sQuestionId': field ?? 'section-$order',
  'sParentQuestionId': null,
  'sParentAnswer': '',
  'sQuestion': field ?? 'Section heading',
  'sQuestionType': type,
  'iOrder': order,
  'brequired': false,
  'sDisplay': display,
  'sAnswer': answer,
};

Map<String, Object?> _childQuestion(
  String field,
  num order,
  String type,
  String parent,
  String answer,
) => {
  ..._question(field, order, type),
  'sParentQuestionId': parent,
  'sParentAnswer': answer,
};

Map<String, Object?> _requestTypes() => {
  'popularCaseList': [
    {'uxType': 'Fixture Other Request', 'caseConfigId': 'Zz9%2Fxy8%2Bqr7%3D'},
    {
      'uxType': 'Illegal Dumping Item Pickup',
      'caseConfigId': 'ab12%2Fcd34%2Bef56%3D',
    },
  ],
  'caseConfigurationList': <Object>[],
  'isPortalUser': false,
};

Map<String, Object?> _caseTypeDetails() => {
  'scaseTypeLst': ['Illegal Dumping Item Pickup'],
  'objCaseConfigWrapper': {
    'sCaseType': 'Illegal Dumping Item Pickup',
    'sCasePriority': 'Normal',
    'sCaseDefaultStatus': 'New',
    'sHideFromWeb': null,
    'sReportAnonymously': true,
    'sUploadRequired': false,
    'locatorRequired': false,
    'dwpContainerLst': null,
    'lstBeforeCaseQuestion': <Object>[],
    'lstCaseQuestion': [
      _question('Description', 9, 'TextArea'),
      {
        ..._question(
          'Residential_Commercial__c',
          1,
          'Picklist',
          answer: 'Residential',
          display: true,
        ),
        'sDefaultValue': 'Residential',
        'sReadOnly': true,
        'sHidden': true,
      },
      _question(null, 2, 'Section'),
      _question('Owner_Phone_Number__c', 3.5, 'Phone'),
      {
        ..._question(
          'Provide_Information_On_Suspect__c',
          4,
          'Picklist',
          display: true,
        ),
        'lstOptions': [
          {'value': 'Yes'},
          {'value': 'No'},
        ],
      },
      _question('Illegally_Dumped_Item_Type__c', 5.0, 'Picklist'),
      _question('Illegally_Dumped_Pickup_Options__c', 6, 'MultiPicklist'),
      _question('Location_of_Loose_Miscellaneous_Debris__c', 7.9, 'Picklist'),
      _question('No_of_Loose_Miscellaneous_Debris__c', 8.2, 'NumberIncrement'),
      _question('ADA_Question__c', 10, 'Picklist'),
    ],
  },
  'contactWrapperResponse': {
    'sUserName': 'fixture-guest-user',
    'bIsLogin': false,
    'isAnonymously': null,
    'lstValidations': <Object>[],
  },
};

Map<String, Object?> _locatorHit() => _envelope(
  isSuccess: true,
  message: 'Locator Success',
  response: jsonEncode({
    'address': _cityHallAddress(),
    'location': {'x': -118.24317, 'y': 34.054047, 'z': 0},
  }),
);

Map<String, Object?> _caseCreated() => _envelope(
  isSuccess: true,
  response: {
    'sCaseNumber': 'SR-FIXTURE-0001',
    'sCaseId': 'fixture-case-id',
    'sAppointmentDates': '',
  },
);

Map<String, Object> _happyReplies() => {
  'fetchInitialDetails': _envelope(isSuccess: true, response: _requestTypes()),
  'fetchCaseTypeDetails': _envelope(
    isSuccess: true,
    response: _caseTypeDetails(),
  ),
  'validateAddress': _locatorHit(),
  'submitCase': _caseCreated(),
};

class _AuraCall {
  _AuraCall({
    required this.method,
    required this.params,
    required this.cacheable,
    required this.pageUri,
    required this.context,
    required this.token,
    required this.r,
    required this.request,
  });

  factory _AuraCall.from(http.Request request) {
    final form = Uri.splitQueryString(request.body);
    final message = jsonDecode(form['message']!) as Map<String, dynamic>;
    final action = (message['actions'] as List).single as Map<String, dynamic>;
    final call = action['params'] as Map<String, dynamic>;
    return _AuraCall(
      method: call['method'] as String,
      params: call['params'] as Map<String, dynamic>,
      cacheable: call['cacheable'] as bool,
      pageUri: form['aura.pageURI']!,
      context: jsonDecode(form['aura.context']!) as Map<String, dynamic>,
      token: form['aura.token']!,
      r: request.url.queryParameters['r']!,
      request: request,
    );
  }

  final String method;
  final Map<String, dynamic> params;
  final bool cacheable;
  final String pageUri;
  final Map<String, dynamic> context;
  final String token;
  final String r;
  final http.Request request;
}

class _FakePortal {
  _FakePortal(
    this.replies, {
    this.failConnection = false,
    this.homePage = _homePage,
  });

  final Map<String, Object> replies;
  final bool failConnection;
  final String homePage;
  final List<http.Request> requests = [];
  final List<_AuraCall> calls = [];

  late final http.Client client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (request.method == 'GET') {
      return http.Response(
        homePage,
        200,
        headers: {'content-type': 'text/html'},
      );
    }
    if (failConnection) {
      throw http.ClientException('Connection refused', request.url);
    }
    final call = _AuraCall.from(request);
    calls.add(call);
    final reply = replies[call.method];
    if (reply is Exception || reply is Error) throw reply!;
    if (reply is http.Response) return reply;
    return _auraReply(reply! as Map<String, Object?>);
  }

  _AuraCall callTo(String method) =>
      calls.singleWhere((call) => call.method == method);
}

class _OfflineHttpClient implements HttpClient {
  bool closed = false;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    throw const SocketException('Offline fixture');
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _logged = <String>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PortalSubmissionClient', () {
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      _logged.clear();
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        _logged.add(message ?? '');
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });
    test(
      'invalid selected item is rejected before any portal requests',
      () async {
        final portal = _FakePortal(_happyReplies());
        final report = Report(
          description: '',
          latitude: 34.05,
          longitude: -118.25,
          createdAt: DateTime(2026),
          itemFamily: 'Bulky Items',
          items: [
            const ReportItem(
              name: 'Not a City option',
              quantity: '1',
              location: 'Curb',
            ),
          ],
        );
        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(report);
        expect(
          result,
          isA<SubmissionFailed>().having(
            (value) => value.kind,
            'kind',
            SubmissionFailureKind.rejected,
          ),
        );
        expect(portal.requests, isEmpty);
      },
    );

    test('changed City item questions block a reviewed payload', () async {
      final config = Map<String, Object?>.from(
        _caseTypeDetails()['objCaseConfigWrapper'] as Map,
      );
      final report = Report(
        description: '',
        latitude: 34.05,
        longitude: -118.25,
        createdAt: DateTime(2026),
        itemFamily: 'Bulky Items',
        items: [
          const ReportItem(
            name: 'Bed Frame (Wood)',
            quantity: '1',
            location: 'Curb',
          ),
        ],
      );
      await expectLater(
        PortalSubmissionClient().prepareInspectorSubmission(
          report,
          fwuid: 'fixture',
          appId: 'fixture',
          caseTypeId: 'fixture',
          requestCount: 1,
          config: config,
          contact: {},
          address: _cityHallAddress(),
          addressStatus: 'Verified',
        ),
        throwsFormatException,
      );
    });

    test('changed City questions cannot dispatch a submission', () async {
      final portal = _FakePortal(_happyReplies());
      final report = Report(
        description: '',
        latitude: 34.05,
        longitude: -118.25,
        createdAt: DateTime(2026),
        itemFamily: 'Bulky Items',
        items: [
          const ReportItem(
            name: 'Bed Frame (Wood)',
            quantity: '1',
            location: 'Curb',
          ),
        ],
      );
      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(report);
      expect(
        result,
        isA<SubmissionFailed>().having(
          (value) => value.kind,
          'kind',
          SubmissionFailureKind.rejected,
        ),
      );
      expect(
        portal.calls.map((call) => call.method),
        isNot(contains('submitCase')),
      );
    });

    test(
      'changed parent is rejected and duplicate field only answers the selected branch',
      () async {
        final config = Map<String, Object?>.from(
          _caseTypeDetails()['objCaseConfigWrapper'] as Map,
        );
        final questions = List<Object?>.from(config['lstCaseQuestion'] as List);
        final type = questions.whereType<Map<String, Object?>>().singleWhere(
          (question) =>
              question['sFieldtoUpdate'] == 'Illegally_Dumped_Item_Type__c',
        );
        type['sParentQuestionId'] = 'Provide_Information_On_Suspect__c';
        type['sParentAnswer'] = 'Yes;No';
        type['lstOptions'] = [
          {'value': 'Bulky Items'},
        ];
        const selectionField = 'Illegally_Dumped_Other_Item_Options__c';
        final quantity = _childQuestion(
          'No_of_Bedframe_Wood__c',
          13,
          'NumberIncrement',
          'wrong-parent',
          'Bed Frame (Wood)',
        );
        questions.addAll([
          {
            ..._childQuestion(
              selectionField,
              11,
              'MultiPicklist',
              'Illegally_Dumped_Item_Type__c',
              'Bulky Items',
            ),
            'lstOptions': [
              {'value': 'Bed Frame (Wood)'},
            ],
          },
          {
            ..._childQuestion(
              'Location_of_Bed_Frame_Wood__c',
              12,
              'Picklist',
              selectionField,
              'Bed Frame (Wood)',
            ),
            'lstOptions': [
              {'value': 'Curb'},
            ],
          },
          quantity,
        ]);
        config['lstCaseQuestion'] = questions;
        final report = Report(
          description: 'Fixture description',
          latitude: 34.05,
          longitude: -118.25,
          createdAt: DateTime(2026),
          itemFamily: 'Bulky Items',
          items: [
            const ReportItem(
              name: 'Bed Frame (Wood)',
              quantity: '2',
              location: 'Curb',
            ),
          ],
        );
        Future<PortalPreparedSubmission> prepare() =>
            PortalSubmissionClient().prepareInspectorSubmission(
              report,
              fwuid: 'fixture',
              appId: 'fixture',
              caseTypeId: 'fixture',
              requestCount: 1,
              config: config,
              contact: {},
              address: _cityHallAddress(),
              addressStatus: 'Verified',
            );
        await expectLater(prepare(), throwsFormatException);
        quantity['sParentQuestionId'] = selectionField;
        questions.add({
          ..._childQuestion(
            'No_of_Bedframe_Wood__c',
            14,
            'NumberIncrement',
            'other-parent',
            'Other',
          ),
          'sQuestionId': 'other-branch',
        });
        questions.add({
          ..._childQuestion(
            'Description',
            15,
            'TextArea',
            'other-parent',
            'Other',
          ),
          'sQuestionId': 'other-description',
        });
        final plan = await prepare();
        final params =
            jsonDecode(plan.actionParamsJson) as Map<String, dynamic>;
        final payload =
            jsonDecode(params['sCaseQuestionJSON'] as String)
                as Map<String, dynamic>;
        final entries = (payload['lstCaseQuestion'] as List)
            .cast<Map<String, dynamic>>();
        expect(
          entries.singleWhere(
            (question) => question['sQuestionId'] == 'No_of_Bedframe_Wood__c',
          )['sAnswer'],
          '2',
        );
        final other = entries.singleWhere(
          (question) => question['sQuestionId'] == 'other-branch',
        );
        expect(other['sAnswer'], '');
        expect(other['sDisplay'], isFalse);
        final otherDescription = entries.singleWhere(
          (question) => question['sQuestionId'] == 'other-description',
        );
        expect(otherDescription['sAnswer'], '');
        expect(otherDescription['sDisplay'], isFalse);
        quantity['sQuestionId'] = 'other-branch';
        await expectLater(prepare(), throwsFormatException);
        quantity['sQuestionId'] = null;
        await expectLater(prepare(), throwsFormatException);
        quantity['sQuestionId'] = 'No_of_Bedframe_Wood__c';
        final suspect = questions.whereType<Map<String, Object?>>().singleWhere(
          (question) =>
              question['sFieldtoUpdate'] == 'Provide_Information_On_Suspect__c',
        );
        suspect['sParentQuestionId'] = 'new-parent';
        await expectLater(prepare(), throwsFormatException);
      },
    );

    test(
      'each item family uses its captured selection and detail fields',
      () async {
        final catalog = await IllegalDumpingCatalog.load();
        for (final family in catalog.families) {
          final item = family.items.first;
          final config = Map<String, Object?>.from(
            _caseTypeDetails()['objCaseConfigWrapper'] as Map,
          );
          final questions = List<Object?>.from(
            config['lstCaseQuestion'] as List,
          );
          final type = questions.whereType<Map<String, Object?>>().singleWhere(
            (question) =>
                question['sFieldtoUpdate'] == 'Illegally_Dumped_Item_Type__c',
          );
          type['sParentQuestionId'] = 'Provide_Information_On_Suspect__c';
          type['sParentAnswer'] = 'Yes;No';
          type['lstOptions'] = [
            {'value': family.name},
          ];
          questions.removeWhere(
            (question) =>
                question is Map &&
                [
                  family.selectionField,
                  item.locationField,
                  item.quantityField,
                ].contains(question['sFieldtoUpdate']),
          );
          questions.addAll([
            {
              ..._childQuestion(
                family.selectionField,
                11,
                'MultiPicklist',
                'Illegally_Dumped_Item_Type__c',
                family.name,
              ),
              'lstOptions': [
                {'value': item.name},
              ],
            },
            {
              ..._childQuestion(
                item.locationField,
                12,
                'Picklist',
                family.selectionField,
                item.name,
              ),
              'lstOptions': [
                {'value': 'Curb'},
              ],
            },
            _childQuestion(
              item.quantityField,
              13,
              'NumberIncrement',
              family.selectionField,
              item.name,
            ),
          ]);
          config['lstCaseQuestion'] = questions;
          final report = Report(
            description: '',
            latitude: 34.05,
            longitude: -118.25,
            createdAt: DateTime(2026),
            itemFamily: family.name,
            items: [
              ReportItem(name: item.name, quantity: '4', location: 'Curb'),
            ],
          );
          final plan = await PortalSubmissionClient()
              .prepareInspectorSubmission(
                report,
                fwuid: 'fixture',
                appId: 'fixture',
                caseTypeId: 'fixture',
                requestCount: 1,
                config: config,
                contact: {},
                address: _cityHallAddress(),
                addressStatus: 'Verified',
              );
          final params =
              jsonDecode(plan.actionParamsJson) as Map<String, dynamic>;
          final payload =
              jsonDecode(params['sCaseQuestionJSON'] as String)
                  as Map<String, dynamic>;
          final answers = {
            for (final question in payload['lstCaseQuestion'] as List)
              question['sFieldtoUpdate']: question['sAnswer'],
          };
          expect(answers[family.selectionField], item.name);
          expect(answers[item.locationField], 'Curb');
          expect(answers[item.quantityField], '4');
        }
      },
    );

    test(
      'selected items use verified City fields in reviewed payload',
      () async {
        final config = Map<String, Object?>.from(
          _caseTypeDetails()['objCaseConfigWrapper'] as Map,
        );
        final questions = List<Object?>.from(config['lstCaseQuestion'] as List);
        final typeQuestion = questions
            .whereType<Map<String, Object?>>()
            .singleWhere(
              (question) =>
                  question['sFieldtoUpdate'] == 'Illegally_Dumped_Item_Type__c',
            );
        typeQuestion['sParentQuestionId'] = 'Provide_Information_On_Suspect__c';
        typeQuestion['sParentAnswer'] = 'Yes;No';
        typeQuestion['lstOptions'] = [
          {'value': 'Bulky Items'},
        ];
        questions.addAll([
          {
            ..._childQuestion(
              'Illegally_Dumped_Other_Item_Options__c',
              11,
              'MultiPicklist',
              'Illegally_Dumped_Item_Type__c',
              'Bulky Items',
            ),
            'lstOptions': [
              {'value': 'Bed Frame (Wood)'},
              {'value': 'Basketball Set'},
            ],
          },
          {
            ..._childQuestion(
              'Location_of_Bed_Frame_Wood__c',
              12,
              'Picklist',
              'Illegally_Dumped_Other_Item_Options__c',
              'Bed Frame (Wood)',
            ),
            'lstOptions': [
              {'value': 'Curb'},
            ],
          },
          _childQuestion(
            'No_of_Bedframe_Wood__c',
            13,
            'NumberIncrement',
            'Illegally_Dumped_Other_Item_Options__c',
            'Bed Frame (Wood)',
          ),
          {
            ..._childQuestion(
              'Location_of_Basketball_Set__c',
              14,
              'Picklist',
              'Illegally_Dumped_Other_Item_Options__c',
              'Basketball Set',
            ),
            'lstOptions': [
              {'value': 'Alley'},
            ],
          },
          _childQuestion(
            'No_of_Basketball_Set__c',
            15,
            'NumberIncrement',
            'Illegally_Dumped_Other_Item_Options__c',
            'Basketball Set',
          ),
        ]);
        config['lstCaseQuestion'] = questions;
        final report = Report(
          description: '',
          latitude: 34.05,
          longitude: -118.25,
          createdAt: DateTime(2026),
          itemFamily: 'Bulky Items',
          items: [
            const ReportItem(
              name: 'Bed Frame (Wood)',
              quantity: '2',
              location: 'Curb',
            ),
            const ReportItem(
              name: 'Basketball Set',
              quantity: '3',
              location: 'Alley',
            ),
          ],
        );
        final plan = await PortalSubmissionClient().prepareInspectorSubmission(
          report,
          fwuid: 'fixture',
          appId: 'fixture',
          caseTypeId: 'fixture',
          requestCount: 1,
          config: config,
          contact: {},
          address: _cityHallAddress(),
          addressStatus: 'Verified',
        );
        final params =
            jsonDecode(plan.actionParamsJson) as Map<String, dynamic>;
        final payload =
            jsonDecode(params['sCaseQuestionJSON'] as String)
                as Map<String, dynamic>;
        final answers = {
          for (final question in payload['lstCaseQuestion'] as List)
            question['sFieldtoUpdate']: question['sAnswer'],
        };
        expect(answers['Illegally_Dumped_Item_Type__c'], 'Bulky Items');
        expect(
          answers['Illegally_Dumped_Other_Item_Options__c'],
          'Bed Frame (Wood);Basketball Set',
        );
        expect(answers['Location_of_Bed_Frame_Wood__c'], 'Curb');
        expect(answers['No_of_Bedframe_Wood__c'], '2');
        expect(answers['Location_of_Basketball_Set__c'], 'Alley');
        expect(answers['No_of_Basketball_Set__c'], '3');
      },
    );

    test('named contact reaches the production submission payload', () async {
      final portal = _FakePortal(_happyReplies());
      final report = Report(
        description: 'Couch',
        latitude: 34.05,
        longitude: -118.25,
        createdAt: DateTime(2026),
        debrisLocation: 'Curb',
        quantity: 1,
        contact: const ReportContact(
          anonymous: false,
          firstName: 'Ada',
          lastName: 'Jones',
          email: 'ada@example.com',
          phone: '5551234567',
        ),
      );
      await PortalSubmissionClient(httpClient: portal.client).send(report);
      final contact =
          jsonDecode(
                portal.callTo('submitCase').params['sObjContact'] as String,
              )
              as Map<String, dynamic>;
      expect(contact['isAnonymously'], false);
      expect(contact['sFirstName'], 'Ada');
      expect(contact['sLastName'], 'Jones');
      expect(contact['sEmail'], 'ada@example.com');
      expect(contact['sPhone'], '5551234567');
      expect(_logged.join(' '), isNot(contains('ada@example.com')));
      expect(_logged.join(' '), isNot(contains('5551234567')));
    });

    test(
      'happy path returns the Service Request number from submitCase',
      () async {
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionAccepted>().having(
            (r) => r.serviceRequestNumber,
            'serviceRequestNumber',
            'SR-FIXTURE-0001',
          ),
        );
        expect(portal.requests.first.method, 'GET');
        expect(
          portal.requests.first.url,
          Uri.https('myla311.lacity.gov', '/s/'),
        );
        expect(portal.calls.map((c) => c.method), [
          'fetchInitialDetails',
          'fetchCaseTypeDetails',
          'validateAddress',
          'submitCase',
        ]);
        expect(portal.calls.map((c) => c.r), ['1', '2', '3', '4']);
        for (final call in portal.calls) {
          expect(
            call.request.url,
            Uri.https('myla311.lacity.gov', '/s/sfsites/aura', {
              'r': call.r,
              'aura.ApexAction.execute': '1',
            }),
          );
          expect(
            call.request.headers['Content-Type'],
            'application/x-www-form-urlencoded; charset=UTF-8',
          );
          expect(
            call.request.headers['User-Agent'],
            contains('LA Dump Report'),
          );
          expect(call.token, 'null');
          expect(call.context['fwuid'], 'fixture-fwuid');
          expect(call.context['loaded'], {
            'APPLICATION@markup://siteforce:communityApp': '1893_fixture-app',
          });
        }
        expect(portal.callTo('fetchInitialDetails').cacheable, isTrue);
        expect(
          portal.callTo('fetchInitialDetails').params,
          <String, dynamic>{},
        );
        expect(
          portal.callTo('fetchCaseTypeDetails').pageUri,
          '/s/report-issue?c__IssueTypeId=ab12%2Fcd34%2Bef56%3D&c__IsPortalUser=true',
        );
        expect(portal.callTo('fetchCaseTypeDetails').params, {
          'caseTypeId': 'ab12/cd34+ef56=',
          'parentWorkOrderId': '',
          'isSNC': false,
        });
        expect(portal.callTo('validateAddress').params, {
          'latitude': 34.054047,
          'longitude': -118.24317,
          'addressType': 'City Boundary',
          'filterCriteria': '',
        });
        expect(portal.callTo('submitCase').params['sFileLinks'], '[]');
      },
    );

    test(
      'submit carries the fixed answers, anonymous contact and photo',
      () async {
        final dir = Directory.systemTemp.createTempSync('portal_client_test_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final photo = File('${dir.path}/photo.jpg')
          ..writeAsBytesSync([1, 2, 3, 4, 5]);
        final portal = _FakePortal(_happyReplies());

        await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(photoPath: photo.path));

        final submit = portal.callTo('submitCase').params;

        final contact =
            jsonDecode(submit['sObjContact'] as String) as Map<String, dynamic>;
        expect(contact['isAnonymously'], isTrue);
        expect(contact['sUserName'], 'fixture-guest-user');

        final caseConfig =
            jsonDecode(submit['sCaseQuestionJSON'] as String)
                as Map<String, dynamic>;
        expect(caseConfig.containsKey('dwpContainerLst'), isFalse);
        final questions = (caseConfig['lstCaseQuestion'] as List)
            .cast<Map<String, dynamic>>();
        expect(questions.map((q) => q['sFieldtoUpdate']), [
          'Residential_Commercial__c',
          'Owner_Phone_Number__c',
          'Provide_Information_On_Suspect__c',
          'Illegally_Dumped_Item_Type__c',
          'Illegally_Dumped_Pickup_Options__c',
          'Location_of_Loose_Miscellaneous_Debris__c',
          'No_of_Loose_Miscellaneous_Debris__c',
          'Description',
          'ADA_Question__c',
        ]);
        expect(questions.map((q) => q['iOrder']), [1, 3, 4, 5, 6, 7, 8, 9, 10]);

        final answers = <String, Map<String, dynamic>>{
          for (final q in questions) q['sFieldtoUpdate'] as String: q,
        };
        expect(answers['Residential_Commercial__c']!['sAnswer'], 'Residential');
        expect(answers['Provide_Information_On_Suspect__c']!['sAnswer'], 'No');
        expect(
          answers['Provide_Information_On_Suspect__c']!['sDisplay'],
          isTrue,
        );
        expect(
          answers['Illegally_Dumped_Item_Type__c']!['sAnswer'],
          "I'm not sure",
        );
        expect(
          answers['Illegally_Dumped_Pickup_Options__c']!['sAnswer'],
          'Loose/Miscellaneous Debris',
        );
        expect(
          answers['Location_of_Loose_Miscellaneous_Debris__c']!['sAnswer'],
          'Curb',
        );
        expect(answers['No_of_Loose_Miscellaneous_Debris__c']!['sAnswer'], '3');
        expect(
          answers['Description']!['sAnswer'],
          'Mattress and boxes at the curb.',
        );
        expect(answers['Owner_Phone_Number__c']!['sAnswer'], '');
        expect(answers['Owner_Phone_Number__c']!['sDisplay'], isFalse);

        final links =
            jsonDecode(submit['sFileLinks'] as String) as List<dynamic>;
        expect(links, [
          {
            'fileData': 'AQIDBAU=',
            'fileName': 'photo.jpg',
            'showImage': true,
            'showPdf': false,
            'fileType': 'jpg',
            'position': null,
          },
        ]);
        expect(
          jsonDecode(submit['addressDetails'] as String),
          _cityHallAddress(),
        );

        final caseFields = submit['sObjCase'] as Map<String, dynamic>;
        expect(caseFields['Type'], 'Illegal Dumping Item Pickup');
        expect(caseFields['Status'], 'New');
        expect(caseFields['Priority'], 'Normal');
        expect(caseFields['Origin'], 'Self Service');
        expect(caseFields['Street_Address__c'], '200 N SPRING ST');
        expect(caseFields['Zipcode__c'], '90012');
        expect(caseFields['Geolocation__Latitude__s'], 34.054047);
        expect(caseFields['Geolocation__Longitude__s'], -118.24317);
        expect(caseFields['Address_Status__c'], 'Locator Success');
        expect(
          caseFields['Google_Address__c'],
          '200 N SPRING ST, LOS ANGELES, CA, 90012',
        );
        expect(caseFields['Address_Entry_Method__c'], 'Device Location');
        expect(caseFields['Session_Tracking_ID__c'], matches(_uuidV4));
        expect(caseFields['Platform_Info__c'], 'iOS');
        expect(caseFields['Device_Info__c'], 'Mobile');
        expect(caseFields['Application_Info__c'], 'LA Dump Report');
        expect(submit['isSNC'], isFalse);
      },
    );

    test('a Portal rejection on submit keeps the Portal message', () async {
      final portal = _FakePortal({
        ..._happyReplies(),
        'submitCase': _envelope(
          isSuccess: false,
          message: 'Owner phone number is required.',
        ),
      });

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
            .having(
              (r) => r.message,
              'message',
              'Owner phone number is required.',
            ),
      );
    });

    test('a failed submit reply with case data blocks another send', () async {
      for (final response in [
        {'sCaseNumber': 'C-EXISTING-CASE'},
        {'sCaseId': 'fixture-case-id'},
      ]) {
        final portal = _FakePortal({
          ..._happyReplies(),
          'submitCase': _envelope(
            isSuccess: false,
            message: 'The Portal returned conflicting details.',
            response: response,
          ),
        });

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionFailed>().having(
            (r) => r.kind,
            'kind',
            SubmissionFailureKind.uncertain,
          ),
          reason: '$response',
        );
      }
    });

    test('a locator rejection stops before submitCase', () async {
      final portal = _FakePortal({
        ..._happyReplies(),
        'validateAddress': _envelope(
          isSuccess: false,
          message: 'Locator Address Invalid',
          response: 'Unable to find address for the specified location.',
        ),
      });

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
            .having((r) => r.message, 'message', 'Locator Address Invalid'),
      );
      expect(portal.calls.map((c) => c.method), isNot(contains('submitCase')));
    });

    test('a dropped connection is reported as a network failure', () async {
      final portal = _FakePortal(_happyReplies(), failConnection: true);

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.network)
            .having((r) => r.message, 'message', 'Could not reach the Portal.'),
      );
    });

    test(
      'an Aura action that is not SUCCESS means the session expired',
      () async {
        final portal = _FakePortal({
          'fetchInitialDetails': http.Response(
            jsonEncode({
              'actions': [
                {
                  'id': '1;a',
                  'state': 'ERROR',
                  'returnValue': null,
                  'error': [
                    {'message': 'fixture error'},
                  ],
                },
              ],
              'context': {},
            }),
            200,
          ),
        });

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionFailed>()
              .having(
                (r) => r.kind,
                'kind',
                SubmissionFailureKind.sessionExpired,
              )
              .having(
                (r) => r.message,
                'message',
                'The Portal session expired. Try again.',
              ),
        );
      },
    );

    test(
      'the home page is URL-decoded before the session ids are read',
      () async {
        final encoded = Uri.encodeComponent(
          '{"fwuid":"fixture-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"1893_fixture-app"}}',
        );
        final portal = _FakePortal(
          _happyReplies(),
          homePage: '<html><body>$encoded</body></html>',
        );

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionAccepted>().having(
            (r) => r.serviceRequestNumber,
            'serviceRequestNumber',
            'SR-FIXTURE-0001',
          ),
        );
        expect(portal.calls.first.context['fwuid'], 'fixture-fwuid');
      },
    );

    test('an Aura exception event means the session expired', () async {
      final portal = _FakePortal({
        'fetchInitialDetails': http.Response(
          jsonEncode({
            'exceptionEvent': true,
            'event': {'descriptor': 'markup://aura:clientOutOfSync'},
          }),
          200,
        ),
      });

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.sessionExpired)
            .having(
              (r) => r.message,
              'message',
              'The Portal session expired. Try again.',
            ),
      );
    });

    test('an HTTP error status is reported as a network failure', () async {
      final portal = _FakePortal({
        'fetchInitialDetails': http.Response('Service Unavailable', 503),
      });

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.network)
            .having(
              (r) => r.message,
              'message',
              'The Portal answered HTTP 503.',
            ),
      );
    });

    test('an unconfirmed submit outcome is uncertain', () async {
      final replies = <Object>[
        _envelope(
          isSuccess: true,
          message: 'Saved',
          response: {'sCaseId': 'fixture-case-id'},
        ),
        _envelope(isSuccess: true, response: {'sCaseNumber': ''}),
        _envelope(isSuccess: true, response: {'sCaseNumber': 123}),
        <String, Object?>{'message': 'Saved'},
        http.Response('Service Unavailable', 503),
        http.Response('Not JSON', 200),
        http.Response('{"actions":[]}', 200),
        http.Response('{"exceptionEvent":true}', 200),
        http.Response('{"actions":[{"state":"ERROR"}]}', 200),
        http.Response(
          '{"actions":[{"state":"SUCCESS","returnValue":{}}]}',
          200,
        ),
        http.ClientException('Reply lost'),
        TimeoutException('Reply lost'),
        const SocketException('Reply lost'),
        StateError('Unexpected response failure'),
      ];

      for (final reply in replies) {
        final portal = _FakePortal({..._happyReplies(), 'submitCase': reply});

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionFailed>()
              .having((r) => r.kind.name, 'kind', 'uncertain')
              .having(
                (r) => r.message,
                'message',
                'The Portal did not confirm whether the report was received. '
                    'Do not submit it again.',
              ),
          reason: '$reply',
        );
      }
    });

    test(
      'every Portal call is logged and the submit payload is summarised',
      () async {
        final dir = Directory.systemTemp.createTempSync('portal_client_test_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final photo = File('${dir.path}/photo.jpg')
          ..writeAsBytesSync([1, 2, 3, 4, 5]);
        final portal = _FakePortal({
          ..._happyReplies(),
          'fetchInitialDetails': _envelope(
            isSuccess: true,
            response: {..._requestTypes(), 'token': 'fixture-secret'},
          ),
        });

        await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(photoPath: photo.path));

        expect(
          _logged,
          contains('[portal] GET /s/ -> HTTP 200 fwuid length 13'),
        );
        expect(_logged, contains('[portal] fetchInitialDetails r=1'));
        expect(_logged, contains('[portal] submitCase r=4'));
        final params = _logged.singleWhere(
          (line) => line.startsWith('[portal] submitCase params '),
        );
        expect(params, contains('9 questions; answered: '));
        expect(params, contains('Provide_Information_On_Suspect__c=No'));
        expect(params, contains('<1 files, 5 bytes>'));
        expect(params, isNot(contains('AQIDBAU=')));
        final submitted = _logged.singleWhere(
          (line) => line.startsWith('[portal] submitCase -> HTTP 200 '),
        );
        expect(submitted, contains('"sCaseNumber":"SR-FIXTURE-0001"'));
        expect(_logged.any((line) => line.contains('fixture-secret')), isFalse);
        expect(_logged.any((line) => line.contains('<redacted>')), isTrue);
      },
    );

    test('missing debris details fail before any request', () async {
      for (final report in [
        _report(debrisLocation: null),
        _report(quantity: null),
      ]) {
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(report);

        expect(
          result,
          isA<SubmissionFailed>()
              .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
              .having((r) => r.message, 'message', 'Missing debris details'),
        );
        expect(portal.requests, isEmpty);
      }
    });

    test(
      'a description over 750 characters fails before any request',
      () async {
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(description: 'x' * 751));

        expect(
          result,
          isA<SubmissionFailed>()
              .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
              .having(
                (r) => r.message,
                'message',
                'Description must be 750 characters or fewer.',
              ),
        );
        expect(portal.requests, isEmpty);
      },
    );

    test('invalid JSON before submission is a network failure', () async {
      final portal = _FakePortal({
        'fetchInitialDetails': http.Response('{', 200),
      });

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report());

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.network)
            .having(
              (r) => r.message,
              'message',
              'The Portal sent an unexpected reply.',
            ),
      );
    });

    test(
      'request types can be returned inside a configuration group',
      () async {
        final initial = _requestTypes();
        final portal = _FakePortal({
          ..._happyReplies(),
          'fetchInitialDetails': _envelope(
            isSuccess: true,
            response: {
              'popularCaseList': <Object>[],
              'caseConfigurationList': [
                {'caseConfigurations': initial['popularCaseList']},
              ],
            },
          ),
        });

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionAccepted>().having(
            (r) => r.serviceRequestNumber,
            'serviceRequestNumber',
            'SR-FIXTURE-0001',
          ),
        );
      },
    );

    for (final failure in [
      (
        error: TimeoutException('Offline fixture'),
        message: 'The Portal did not answer in time.',
      ),
      (
        error: const SocketException('Offline fixture'),
        message: 'Could not reach the Portal.',
      ),
    ]) {
      test(
        '${failure.error.runtimeType} before submission is retryable',
        () async {
          final portal = _FakePortal({'fetchInitialDetails': failure.error});

          final result = await PortalSubmissionClient(
            httpClient: portal.client,
          ).send(_report());

          expect(
            result,
            isA<SubmissionFailed>()
                .having((r) => r.kind, 'kind', SubmissionFailureKind.network)
                .having((r) => r.message, 'message', failure.message),
          );
        },
      );
    }

    test(
      'an invalid UTF-8 escape does not hide valid session details',
      () async {
        final portal = _FakePortal(_happyReplies(), homePage: '$_homePage%FF');

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report());

        expect(
          result,
          isA<SubmissionAccepted>().having(
            (r) => r.serviceRequestNumber,
            'serviceRequestNumber',
            'SR-FIXTURE-0001',
          ),
        );
      },
    );

    test(
      'the default HTTP client is closed after an offline failure',
      () async {
        final client = _OfflineHttpClient();

        final result = await HttpOverrides.runZoned(
          () => PortalSubmissionClient().send(_report()),
          createHttpClient: (_) => client,
        );

        expect(
          result,
          isA<SubmissionFailed>()
              .having((r) => r.kind, 'kind', SubmissionFailureKind.network)
              .having(
                (r) => r.message,
                'message',
                'Could not reach the Portal.',
              ),
        );
        expect(client.closed, isTrue);
      },
    );

    test(
      'large photo normalization preserves the three-photo order and originals',
      () async {
        final dir = Directory.systemTemp.createTempSync(
          'portal_normalization_',
        );
        addTearDown(() => dir.deleteSync(recursive: true));
        final small = File('${dir.path}/small.jpg')
          ..writeAsBytesSync([1, 2, 3]);
        final boundary = File('${dir.path}/boundary.png')
          ..writeAsBytesSync(List.filled(500000, 7));
        final png = image.encodePng(image.Image(width: 1200, height: 600));
        final original = [...png, ...List.filled(500001 - png.length, 0)];
        final large = File('${dir.path}/landscape.png')
          ..writeAsBytesSync(original);
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(photoPaths: [small.path, boundary.path, large.path]));

        expect(result, isA<SubmissionAccepted>());
        final links =
            (jsonDecode(
                      portal.callTo('submitCase').params['sFileLinks']
                          as String,
                    )
                    as List)
                .cast<Map<String, dynamic>>();
        expect(links.map((p) => p['fileName']), [
          'small.jpg',
          'boundary.png',
          'landscape.png',
        ]);
        expect(base64Decode(links[0]['fileData'] as String), [1, 2, 3]);
        expect(
          base64Decode(links[1]['fileData'] as String),
          List.filled(500000, 7),
        );
        final sent = base64Decode(links[2]['fileData'] as String);
        expect(sent.take(2), [255, 216]);
        final decoded = image.decodeJpg(sent)!;
        expect((decoded.width, decoded.height), (600, 300));
        expect(sent.length, lessThan(500000));
        expect(large.readAsBytesSync(), original);
        expect(boundary.lengthSync(), 500000);
        expect(small.readAsBytesSync(), [1, 2, 3]);
      },
    );

    test(
      'large portrait photo normalization respects EXIF orientation without enlarging small images',
      () async {
        final dir = Directory.systemTemp.createTempSync('portal_orientation_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final rotated = image.Image(width: 1200, height: 600);
        for (var y = 0; y < rotated.height; y++) {
          for (var x = 0; x < rotated.width; x++) {
            rotated.setPixelRgb(x, y, y < 300 ? 240 : 0, 0, y < 300 ? 0 : 240);
          }
        }
        rotated.exif.imageIfd.orientation = 6;
        final rotatedJpg = image.encodeJpg(rotated);
        final compactPng = image.encodePng(image.Image(width: 80, height: 120));
        final originals = [
          [...rotatedJpg, ...List.filled(500001 - rotatedJpg.length, 0)],
          [...compactPng, ...List.filled(500001 - compactPng.length, 0)],
        ];
        final files = [
          for (var i = 0; i < originals.length; i++)
            File('${dir.path}/photo$i.jpg')..writeAsBytesSync(originals[i]),
        ];
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(photoPaths: files.map((f) => f.path).toList()));

        expect(result, isA<SubmissionAccepted>());
        final links =
            (jsonDecode(
                      portal.callTo('submitCase').params['sFileLinks']
                          as String,
                    )
                    as List)
                .cast<Map<String, dynamic>>();
        final oriented = image.decodeJpg(
          base64Decode(links[0]['fileData'] as String),
        )!;
        final compact = image.decodeJpg(
          base64Decode(links[1]['fileData'] as String),
        )!;
        expect((oriented.width, oriented.height), (300, 600));
        expect(oriented.getPixel(25, 25).b, greaterThan(200));
        expect(oriented.getPixel(275, 25).r, greaterThan(200));
        expect(oriented.exif.imageIfd.hasOrientation, isFalse);
        expect((compact.width, compact.height), (80, 120));
        for (var i = 0; i < files.length; i++) {
          expect(files[i].readAsBytesSync(), originals[i]);
        }
      },
    );

    test('an undecodable large photo is rejected before any request', () async {
      final dir = Directory.systemTemp.createTempSync('portal_invalid_photo_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final corruptPng = image.encodePng(image.Image(width: 1, height: 1));
      corruptPng[29] ^= 255;
      for (final prefix in [
        <int>[1],
        <int>[255, 216, 255, 224, 0, 16],
        <int>[137, 80, 78, 71, 13, 10, 26, 10],
        corruptPng,
      ]) {
        final original = [...prefix, ...List.filled(500001 - prefix.length, 1)];
        final photo = File('${dir.path}/broken.jpg')
          ..writeAsBytesSync(original);
        final portal = _FakePortal(_happyReplies());

        final result = await PortalSubmissionClient(
          httpClient: portal.client,
        ).send(_report(photoPath: photo.path));

        expect(
          result,
          isA<SubmissionFailed>()
              .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
              .having(
                (r) => r.message,
                'message',
                'The photo could not be prepared. Choose it again.',
              ),
        );
        expect(portal.requests, isEmpty);
        expect(photo.readAsBytesSync(), original);
      }
    });

    test('an unreadable photo fails before any request', () async {
      final dir = Directory.systemTemp.createTempSync('portal_client_test_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final portal = _FakePortal(_happyReplies());

      final result = await PortalSubmissionClient(
        httpClient: portal.client,
      ).send(_report(photoPath: '${dir.path}/missing.jpg'));

      expect(
        result,
        isA<SubmissionFailed>()
            .having((r) => r.kind, 'kind', SubmissionFailureKind.rejected)
            .having(
              (r) => r.message,
              'message',
              'The photo could not be read. Choose it again.',
            ),
      );
      expect(portal.requests, isEmpty);
    });
  });
}
