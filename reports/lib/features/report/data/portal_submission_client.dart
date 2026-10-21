import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;

import 'package:reports/features/report/domain/report.dart';

part 'portal_aura_session.dart';
part 'portal_payload_builder.dart';
part 'portal_photo_payload.dart';

const _host = 'myla311.lacity.gov';
const _userAgent = 'LA Dump Report (iOS app)';
const _requestTimeout = Duration(seconds: 60);
const _maxDescriptionLength = 750;
const _unexpectedReply = 'The Portal sent an unexpected reply.';
const _sessionExpired = 'The Portal session expired. Try again.';
const _uncertainReply =
    'The Portal did not confirm whether the report was received. '
    'Do not submit it again.';

typedef _Json = Map<String, dynamic>;

class PortalPreparedSubmission {
  PortalPreparedSubmission._({
    required this.report,
    required this.destination,
    required this.pageUri,
    required this.actionParamsJson,
    required String fwuid,
    required String appId,
    required int requestCount,
    required PortalSubmissionClient owner,
  }) : _fwuid = fwuid,
       _appId = appId,
       _requestCount = requestCount,
       _owner = owner;
  final Report report;
  final String destination;
  final String pageUri;
  final String actionParamsJson;
  final String _fwuid;
  final String _appId;
  final int _requestCount;
  final PortalSubmissionClient _owner;
  bool _dispatched = false;
}

class PortalSubmissionClient implements SubmissionClient {
  PortalSubmissionClient({http.Client? httpClient}) : _httpClient = httpClient;

  static const illegalDumpingRequestType = 'Illegal Dumping Item Pickup';

  final http.Client? _httpClient;

  @override
  Future<SubmissionResult> send(Report report) async {
    final owned = _httpClient == null;
    final client = _httpClient ?? http.Client();
    try {
      return await _submit(client, report);
    } on _Failure catch (failure) {
      return SubmissionFailed(failure.kind, failure.message);
    } on FormatException {
      return SubmissionFailed(SubmissionFailureKind.network, _unexpectedReply);
    } finally {
      if (owned) client.close();
    }
  }

  Future<SubmissionResult> _submit(http.Client client, Report report) async {
    final photoLinks = await _validatedPhotos(report);

    final portal = await _PortalSession.open(client);
    final caseTypeId = Uri.decodeComponent(await portal.requestTypeId());
    final issuePage =
        '/s/report-issue?c__IssueTypeId=${Uri.encodeComponent(caseTypeId)}'
        '&c__IsPortalUser=true';
    final caseType = await portal.caseTypeDetails(caseTypeId, issuePage);
    final config = _map(caseType['objCaseConfigWrapper']);
    final contact = _map(caseType['contactWrapperResponse']);
    final lookup = await portal.locate(
      report.latitude,
      report.longitude,
      issuePage,
    );
    final number = await portal.submitCase(
      _preparedParams(
        report,
        config,
        contact,
        lookup.address,
        lookup.status,
        photoLinks,
      ),
      issuePage,
    );
    return SubmissionAccepted(number);
  }

  Future<PortalPreparedSubmission> prepareInspectorSubmission(
    Report report, {
    required String fwuid,
    required String appId,
    required String caseTypeId,
    required int requestCount,
    required Map<String, Object?> config,
    required Map<String, Object?> contact,
    required Map<String, Object?> address,
    required String addressStatus,
  }) async {
    try {
      final photos = await _validatedPhotos(report);
      final params = _preparedParams(
        report,
        Map<String, dynamic>.from(config),
        Map<String, dynamic>.from(contact),
        Map<String, dynamic>.from(address),
        addressStatus,
        photos,
      );
      return PortalPreparedSubmission._(
        report: report,
        destination: Uri.https(_host, '/s/sfsites/aura', {
          'r': '${requestCount + 1}',
          'aura.ApexAction.execute': '1',
        }).toString(),
        pageUri:
            '/s/report-issue?c__IssueTypeId=${Uri.encodeComponent(caseTypeId)}&c__IsPortalUser=true',
        actionParamsJson: jsonEncode(params),
        fwuid: fwuid,
        appId: appId,
        requestCount: requestCount,
        owner: this,
      );
    } on _Failure catch (failure) {
      throw FormatException(failure.message);
    }
  }

  Future<SubmissionResult> sendPrepared(
    PortalPreparedSubmission plan, {
    Future<void>? abortTrigger,
  }) async {
    if (!identical(plan._owner, this) || plan._dispatched) {
      return SubmissionFailed(
        SubmissionFailureKind.rejected,
        'The reviewed plan belongs to another client. No request sent.',
      );
    }
    plan._dispatched = true;
    final owned = _httpClient == null;
    final client = _httpClient ?? http.Client();
    try {
      final session = _PortalSession._(
        client,
        plan._fwuid,
        plan._appId,
        abortTrigger: abortTrigger,
        fixedDestination: true,
      ).._requestCount = plan._requestCount;
      final number = await session.submitCase(
        _map(jsonDecode(plan.actionParamsJson)),
        plan.pageUri,
      );
      return SubmissionAccepted(number);
    } on _Failure catch (failure) {
      return SubmissionFailed(failure.kind, failure.message);
    } finally {
      if (owned) client.close();
    }
  }
}

void _log(String line) {
  if (kDebugMode) debugPrint(_redact(line));
}

final _secretValue = RegExp(r'((?:token|sid|csrf)\\?"\s*:\s*\\?")[^"\\]*');

String _redact(String text) =>
    text.replaceAllMapped(_secretValue, (m) => '${m[1]}<redacted>');

String _clip(String text) => text.substring(0, min(text.length, 1000));

Map<String, Object?> _logView(Map<String, Object?> params) {
  final questions = _objects(
    _map(jsonDecode(params['sCaseQuestionJSON'] as String))['lstCaseQuestion'],
  );
  final answered = [
    for (final question in questions)
      if (question['sAnswer'] is String &&
          (question['sAnswer'] as String).isNotEmpty)
        '${question['sFieldtoUpdate']}=${question['sAnswer']}',
  ];
  final photos = _objects(jsonDecode(params['sFileLinks'] as String));
  final bytes = photos.fold<int>(
    0,
    (sum, photo) => sum + base64Decode(photo['fileData'] as String).length,
  );
  return {
    ...params,
    'sCaseQuestionJSON':
        '${questions.length} questions; answered: ${answered.join(', ')}',
    'sFileLinks': '<${photos.length} files, $bytes bytes>',
  };
}
