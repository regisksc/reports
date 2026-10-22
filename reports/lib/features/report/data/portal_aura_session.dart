part of 'portal_submission_client.dart';

class _PortalSession {
  _PortalSession._(
    this._client,
    this._fwuid,
    this._appId, {
    Future<void>? abortTrigger,
    bool fixedDestination = false,
  }) : _abortTrigger = abortTrigger,
       _fixedDestination = fixedDestination;

  final http.Client _client;
  final String _fwuid;
  final String _appId;
  final Future<void>? _abortTrigger;
  final bool _fixedDestination;
  int _requestCount = 0;

  static Future<_PortalSession> open(http.Client client) async {
    final page = await _send(
      client.get(
        Uri.https(_host, '/s/'),
        headers: {'Accept': 'text/html', 'User-Agent': _userAgent},
      ),
    );
    final html = _unquote(utf8.decode(page.bodyBytes, allowMalformed: true));
    final fwuid = RegExp(r'"fwuid":"([^"]+)"').firstMatch(html)?.group(1);
    final appId = RegExp(
      r'"loaded":\{"APPLICATION@markup://siteforce:communityApp":"([^"]+)"',
    ).firstMatch(html)?.group(1);
    _log(
      '[portal] GET /s/ -> HTTP ${page.statusCode} fwuid length ${fwuid?.length ?? 0}',
    );
    _requireOk(page);
    if (fwuid == null || appId == null) {
      throw const _Failure(
        SubmissionFailureKind.network,
        'The Portal did not return a session.',
      );
    }
    return _PortalSession._(client, fwuid, appId);
  }

  Future<String> requestTypeId() async {
    final envelope = await _apex(
      classname: 'X11_H_ParentController',
      method: 'fetchInitialDetails',
      params: const {},
      pageUri: '/s/',
      cacheable: true,
    );
    final response = _payloadOf(_succeeded(envelope));
    final types = [
      ..._objects(response['popularCaseList']),
      for (final group in _objects(response['caseConfigurationList']))
        ..._objects(group['caseConfigurations']),
    ];
    final matches = types.where(
      (type) =>
          type['uxType'] == PortalSubmissionClient.illegalDumpingRequestType,
    );
    final id = matches.isEmpty ? null : matches.first['caseConfigId'];
    if (id is! String || id.isEmpty) {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'The Portal does not list Illegal Dumping Item Pickup.',
      );
    }
    return id;
  }

  Future<_Json> caseTypeDetails(String caseTypeId, String issuePage) async {
    final envelope = await _apex(
      classname: 'X11_RI_ParentController',
      method: 'fetchCaseTypeDetails',
      params: {
        'caseTypeId': caseTypeId,
        'parentWorkOrderId': '',
        'isSNC': false,
      },
      pageUri: issuePage,
    );
    return _payloadOf(_succeeded(envelope));
  }

  Future<({_Json address, String status})> locate(
    double latitude,
    double longitude,
    String issuePage,
  ) async {
    final envelope = _succeeded(
      await _apex(
        classname: 'LA_AddressController',
        method: 'validateAddress',
        params: {
          'latitude': latitude,
          'longitude': longitude,
          'addressType': 'City Boundary',
          'filterCriteria': '',
        },
        pageUri: issuePage,
      ),
    );
    return (
      address: _map(_payloadOf(envelope)['address']),
      status: _portalMessage(envelope),
    );
  }

  Future<String> submitCase(_Json params, String issuePage) async {
    final _Json envelope;
    try {
      envelope = await _apex(
        classname: 'X11_RI_ParentController',
        method: 'submitCase',
        params: params,
        pageUri: issuePage,
      );
    } catch (_) {
      throw const _Failure(SubmissionFailureKind.uncertain, _uncertainReply);
    }
    final response = envelope['response'];
    if (envelope['isSuccess'] == false && response == null) {
      throw _Failure(SubmissionFailureKind.rejected, _portalMessage(envelope));
    }
    final number = response is _Json ? response['sCaseNumber'] : null;
    if (envelope['isSuccess'] != true || number is! String || number.isEmpty) {
      throw const _Failure(SubmissionFailureKind.uncertain, _uncertainReply);
    }
    return number;
  }

  Future<_Json> _apex({
    required String classname,
    required String method,
    required Map<String, Object?> params,
    required String pageUri,
    bool cacheable = false,
  }) async {
    final message = jsonEncode({
      'actions': [
        {
          'id': '1;a',
          'descriptor': r'aura://ApexActionController/ACTION$execute',
          'callingDescriptor': 'UNKNOWN',
          'params': {
            'namespace': '',
            'classname': classname,
            'method': method,
            'params': params,
            'cacheable': cacheable,
            'isContinuation': false,
          },
        },
      ],
    });
    final context = jsonEncode({
      'mode': 'PROD',
      'fwuid': _fwuid,
      'app': 'siteforce:communityApp',
      'loaded': {'APPLICATION@markup://siteforce:communityApp': _appId},
      'dn': [],
      'globals': {},
      'uad': true,
    });
    _requestCount++;
    _log('[portal] $method r=$_requestCount');
    if (method == 'submitCase') {
      _log('[portal] submitCase params ${jsonEncode(_logView(params))}');
    }
    final response = await _send(
      _post(
        Uri.https(_host, '/s/sfsites/aura', {
          'r': '$_requestCount',
          'aura.ApexAction.execute': '1',
        }),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'User-Agent': _userAgent,
          'Accept': '*/*',
        },
        body: _formBody({
          'message': message,
          'aura.context': context,
          'aura.pageURI': pageUri,
          'aura.token': 'null',
        }),
      ),
    );
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    String? envelope;
    try {
      _requireOk(response);
      final reply = _map(jsonDecode(body));
      if (reply['exceptionEvent'] == true) {
        throw const _Failure(
          SubmissionFailureKind.sessionExpired,
          _sessionExpired,
        );
      }
      final actions = _objects(reply['actions']);
      if (actions.isEmpty) {
        throw const _Failure(SubmissionFailureKind.network, _unexpectedReply);
      }
      if (actions.first['state'] != 'SUCCESS') {
        throw const _Failure(
          SubmissionFailureKind.sessionExpired,
          _sessionExpired,
        );
      }
      final raw = _map(actions.first['returnValue'])['returnValue'];
      if (raw is! String) {
        throw const _Failure(SubmissionFailureKind.network, _unexpectedReply);
      }
      envelope = raw;
      return _map(jsonDecode(raw));
    } finally {
      final shown = method == 'submitCase' && envelope != null
          ? envelope
          : _clip(body);
      _log('[portal] $method -> HTTP ${response.statusCode} $shown');
    }
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) {
    final abort = _abortTrigger;
    if (abort == null && !_fixedDestination) {
      return _client.post(uri, headers: headers, body: body);
    }
    final request = http.AbortableRequest('POST', uri, abortTrigger: abort)
      ..followRedirects = false
      ..headers.addAll(headers)
      ..body = body;
    return _client.send(request).then(http.Response.fromStream);
  }
}

class _Failure implements Exception {
  const _Failure(this.kind, this.message);

  final SubmissionFailureKind kind;
  final String message;
}

Future<http.Response> _send(Future<http.Response> request) async {
  try {
    return await request.timeout(_requestTimeout);
  } on http.ClientException {
    throw const _Failure(
      SubmissionFailureKind.network,
      'Could not reach the Portal.',
    );
  } on TimeoutException {
    throw const _Failure(
      SubmissionFailureKind.network,
      'The Portal did not answer in time.',
    );
  } on SocketException {
    throw const _Failure(
      SubmissionFailureKind.network,
      'Could not reach the Portal.',
    );
  }
}

String _unquote(String text) =>
    text.replaceAllMapped(RegExp(r'(?:%[0-9A-Fa-f]{2})+'), (match) {
      try {
        return Uri.decodeComponent(match[0]!);
      } on FormatException {
        return match[0]!;
      }
    });

String _formBody(Map<String, String> fields) => fields.entries
    .map(
      (e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
    )
    .join('&');

_Json _map(Object? value) {
  if (value is _Json) return value;
  throw const _Failure(SubmissionFailureKind.network, _unexpectedReply);
}

List<_Json> _objects(Object? value) =>
    value is List ? value.whereType<_Json>().toList() : const [];

_Json _payloadOf(_Json envelope) {
  final response = envelope['response'];
  return _map(response is String ? jsonDecode(response) : response);
}

_Json _succeeded(_Json envelope) {
  if (envelope['isSuccess'] != true) {
    throw _Failure(SubmissionFailureKind.rejected, _portalMessage(envelope));
  }
  return envelope;
}

String _portalMessage(_Json envelope) {
  final message = envelope['message'];
  return message is String && message.isNotEmpty
      ? message
      : 'No error details returned';
}

void _requireOk(http.Response response) {
  if (response.statusCode != 200) {
    throw _Failure(
      SubmissionFailureKind.network,
      'The Portal answered HTTP ${response.statusCode}.',
    );
  }
}
