part of 'dev_api_engine.dart';

mixin _DevApiReadSession on _DevApiState {
  DevApiRequest preset(
    DevApiOperation operation, {
    Map<String, Object?> arguments = const {},
  }) {
    if (operation == DevApiOperation.bootstrap) {
      return const DevApiRequest(
        method: 'GET',
        url: '$_origin/s/',
        headersText: '{"Accept":"text/html"}',
      );
    }
    final typeId = _caseTypeId ?? '';
    final latitude = num.tryParse('${arguments['latitude']}');
    final longitude = num.tryParse('${arguments['longitude']}');
    if ((operation == DevApiOperation.validateAddress ||
            operation == DevApiOperation.nearby) &&
        (latitude?.toDouble() != _validatedLatitude ||
            longitude?.toDouble() != _validatedLongitude)) {
      _address = null;
      _addressStatus = null;
    }
    final method = switch (operation) {
      DevApiOperation.requestTypes => 'fetchInitialDetails',
      DevApiOperation.caseTypeDetails => 'fetchCaseTypeDetails',
      DevApiOperation.validateAddress => 'validateAddress',
      _ => 'getRelatedCaseLst',
    };
    final params = switch (operation) {
      DevApiOperation.requestTypes => <String, Object?>{},
      DevApiOperation.caseTypeDetails => {
        'caseTypeId': typeId,
        'parentWorkOrderId': '',
        'isSNC': false,
      },
      DevApiOperation.validateAddress => {
        'latitude': latitude,
        'longitude': longitude,
        'addressType': 'City Boundary',
        'filterCriteria': '',
      },
      _ => {
        'caseType': 'Illegal Dumping Item Pickup',
        'caseLatitude': _address?['Y'],
        'caseLongitude': _address?['X'],
      },
    };
    return DevApiRequest(
      method: 'POST',
      url:
          '$_origin$_auraPath?r=${_requestCount + 1}&aura.ApexAction.execute=1',
      headersText: jsonEncode({'Content-Type': _contentType, 'Accept': '*/*'}),
      bodyText: Uri(
        queryParameters: {
          'message': jsonEncode({
            'actions': [
              {
                'id': '1;a',
                'descriptor': r'aura://ApexActionController/ACTION$execute',
                'callingDescriptor': 'UNKNOWN',
                'params': {
                  'namespace': '',
                  'classname': _classes[method],
                  'method': method,
                  'params': params,
                  'cacheable': operation == DevApiOperation.requestTypes,
                  'isContinuation': false,
                },
              },
            ],
          }),
          'aura.context': jsonEncode({
            'mode': 'PROD',
            'fwuid': _fwuid ?? '',
            'app': 'siteforce:communityApp',
            'loaded': {
              'APPLICATION@markup://siteforce:communityApp': _appId ?? '',
            },
            'dn': [],
            'globals': {},
            'uad': true,
          }),
          'aura.pageURI': operation == DevApiOperation.requestTypes
              ? '/s/'
              : '/s/report-issue?c__IssueTypeId=${Uri.encodeComponent(typeId)}&c__IsPortalUser=true',
          'aura.token': 'null',
        },
      ).query,
    );
  }

  Future<DevApiResponse> run(DevApiRequest value) async {
    if (_disposed) {
      throw const DevApiException(
        'Inspector is closed. No request sent.',
        'disposed',
      );
    }
    if (_active != null || _submitting) {
      throw const DevApiException('A request is already running.', 'busy');
    }
    final uri = Uri.tryParse(value.url.trim());
    final method = value.method.trim().toUpperCase();
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.replaceFirst(RegExp(r'\.+$'), '') != 'myla311.lacity.gov' ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const DevApiException(
        'Use HTTPS on the standard port without embedded credentials or fragments. No request sent.',
        'blocked',
      );
    }
    final actions = <Map<String, Object?>>[];
    if ((method == 'GET' || method == 'HEAD') &&
        uri.path == '/s/' &&
        !uri.hasQuery) {
      if (method == 'GET') {
        invalidate();
        _fwuid = null;
        _appId = null;
        _caseTypeId = null;
        _config = null;
        _contact = null;
        _requestCount = 0;
      }
    } else if (method == 'POST' && uri.path == _auraPath) {
      if (uri.queryParametersAll.entries.any(
        (entry) =>
            entry.value.length != 1 ||
            (entry.key != 'r' && entry.key != 'aura.ApexAction.execute') ||
            (entry.key == 'r' &&
                !RegExp(r'^\d+$').hasMatch(entry.value.single)) ||
            (entry.key == 'aura.ApexAction.execute' &&
                entry.value.single != '1'),
      )) {
        throw const DevApiException(
          'Unknown City query actions are blocked. No request sent.',
          'blocked',
        );
      }
      try {
        final fields = Uri(query: value.bodyText).queryParametersAll;
        if (fields.length != 4 ||
            fields.keys.any(
              (key) => !{
                'message',
                'aura.context',
                'aura.pageURI',
                'aura.token',
              }.contains(key),
            ) ||
            fields.values.any((values) => values.length != 1) ||
            fields['aura.token']?.single != 'null') {
          throw const FormatException('Invalid Aura form fields');
        }
        final Object? message = jsonDecode(fields['message']!.single);
        if (message is! Map<String, Object?> ||
            message.keys.any((key) => key != 'actions') ||
            message['actions'] is! List<Object?> ||
            (message['actions']! as List<Object?>).isEmpty) {
          throw const FormatException('Missing Aura actions');
        }
        for (final action in message['actions']! as List<Object?>) {
          if (action is! Map<String, Object?> ||
              action['descriptor'] !=
                  r'aura://ApexActionController/ACTION$execute' ||
              action['params'] is! Map<String, Object?>) {
            throw const FormatException('Invalid Aura action');
          }
          final params = action['params']! as Map<String, Object?>;
          if (params['namespace'] != '' ||
              params['isContinuation'] != false ||
              !_classes.containsKey(params['method']) ||
              _classes[params['method']] != params['classname']) {
            throw const DevApiException(
              'Unknown or state-changing City actions are blocked. No request sent.',
              'blocked',
            );
          }
          actions.add(params);
        }
      } on FormatException {
        throw const DevApiException(
          'Invalid Aura request. No request sent.',
          'invalid',
        );
      }
      if (_fwuid == null || _appId == null) {
        throw const DevApiException(
          'Run Guest bootstrap first. No request sent.',
          'invalid',
        );
      }
      for (final action in actions) {
        final params = action['params'];
        if (params is! Map<String, Object?>) {
          throw const DevApiException(
            'Action arguments must be an object. No request sent.',
            'invalid',
          );
        }
        if (action['method'] == 'fetchCaseTypeDetails' &&
            (params['caseTypeId'] is! String ||
                (params['caseTypeId']! as String).isEmpty)) {
          throw const DevApiException(
            'Run Find Illegal Dumping Item Pickup first. No request sent.',
            'invalid',
          );
        }
        if (action['method'] == 'validateAddress' ||
            action['method'] == 'getRelatedCaseLst') {
          final lat =
              params[action['method'] == 'validateAddress'
                  ? 'latitude'
                  : 'caseLatitude'];
          final lng =
              params[action['method'] == 'validateAddress'
                  ? 'longitude'
                  : 'caseLongitude'];
          if (lat is! num ||
              lng is! num ||
              !lat.isFinite ||
              !lng.isFinite ||
              lat.abs() > 90 ||
              lng.abs() > 180) {
            throw const DevApiException(
              'Enter valid coordinates. No request sent.',
              'invalid',
            );
          }
        }
      }
      for (final action in actions) {
        if (action['method'] == 'validateAddress') {
          final params = action['params']! as Map<String, Object?>;
          _address = null;
          _addressStatus = null;
          _validatedLatitude = (params['latitude']! as num).toDouble();
          _validatedLongitude = (params['longitude']! as num).toDouble();
        }
      }
      _prepared = null;
      _revision++;
      _requestCount++;
    } else {
      throw const DevApiException(
        'Only bootstrap GET/HEAD and documented Aura reads are allowed. No request sent.',
        'blocked',
      );
    }
    final Map<String, String> headers;
    try {
      final Object? decoded = jsonDecode(value.headersText);
      if (decoded is! Map<String, Object?> ||
          decoded.values.any((value) => value is! String)) {
        throw const FormatException('Headers must be a JSON string map');
      }
      headers = decoded.map((key, value) => MapEntry(key, value! as String));
    } on FormatException {
      throw const DevApiException(
        'Headers must be a JSON object of strings. No request sent.',
        'invalid',
      );
    }
    final abort = Completer<void>();
    final complete = Completer<DevApiResponse>();
    _abort = abort;
    _active = complete;
    _timer = Timer(
      timeout,
      () => _stop(
        const DevApiException(
          'Request timed out locally. No HTTP response received.',
          'timeout',
        ),
      ),
    );
    final request = http.AbortableRequest(
      method,
      uri,
      abortTrigger: abort.future,
    )..followRedirects = false;
    request.headers.addAll(headers);
    if (method == 'POST') {
      request.headers['Content-Type'] = _contentType;
      request.body = value.bodyText;
    }
    unawaited(_dispatch(request, complete, actions));
    return complete.future;
  }

  Future<void> _dispatch(
    http.BaseRequest request,
    Completer<DevApiResponse> complete,
    List<Map<String, Object?>> actions,
  ) async {
    final watch = Stopwatch()..start();
    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if (!identical(_active, complete)) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _remember(response.body, request.method, actions);
      }
      complete.complete(
        DevApiResponse(
          statusCode: response.statusCode,
          headers: response.headers,
          body: response.body,
          elapsed: watch.elapsed,
          requestUrl: request.url.toString(),
        ),
      );
    } on Object catch (error) {
      if (identical(_active, complete)) {
        complete.completeError(
          DevApiException('No HTTP response: $error', 'network'),
        );
      }
    } finally {
      if (identical(_active, complete)) {
        _timer?.cancel();
        _timer = null;
        _active = null;
        _abort = null;
      }
    }
  }

  void _remember(
    String body,
    String method,
    List<Map<String, Object?>> actions,
  ) {
    if (method == 'GET') {
      final decoded = body.replaceAllMapped(RegExp(r'(?:%[0-9A-Fa-f]{2})+'), (
        match,
      ) {
        try {
          return Uri.decodeComponent(match[0]!);
        } on FormatException {
          return match[0]!;
        }
      });
      _fwuid = RegExp(r'"fwuid":"([^"]+)"').firstMatch(decoded)?.group(1);
      _appId = RegExp(
        r'"loaded":\{"APPLICATION@markup://siteforce:communityApp":"([^"]+)"',
      ).firstMatch(decoded)?.group(1);
    } else {
      try {
        final Object? outer = jsonDecode(body);
        if (outer is! Map<String, Object?> ||
            outer['actions'] is! List<Object?>) {
          return;
        }
        for (final action in outer['actions']! as List<Object?>) {
          if (action is! Map<String, Object?> ||
              action['state'] != 'SUCCESS' ||
              action['returnValue'] is! Map<String, Object?>) {
            continue;
          }
          final raw =
              (action['returnValue']! as Map<String, Object?>)['returnValue'];
          Object? envelope = raw is String ? jsonDecode(raw) : raw;
          if (envelope is Map<String, Object?> &&
              envelope['response'] is String) {
            envelope = {
              ...envelope,
              'response': jsonDecode(envelope['response']! as String),
            };
          }
          if (envelope is! Map<String, Object?> ||
              envelope['isSuccess'] != true ||
              envelope['response'] is! Map<String, Object?>) {
            continue;
          }
          final data = envelope['response']! as Map<String, Object?>;
          final method = actions.first['method'];
          if (method == 'fetchCaseTypeDetails') {
            _config = data['objCaseConfigWrapper'] is Map<String, Object?>
                ? data['objCaseConfigWrapper']! as Map<String, Object?>
                : null;
            _contact = data['contactWrapperResponse'] is Map<String, Object?>
                ? data['contactWrapperResponse']! as Map<String, Object?>
                : null;
          }
          if (method == 'validateAddress') {
            _address = data['address'] is Map<String, Object?>
                ? data['address']! as Map<String, Object?>
                : null;
            _addressStatus = envelope['message'] as String?;
          }
          final types = <Object?>[
            if (data['popularCaseList'] is List<Object?>)
              ...data['popularCaseList']! as List<Object?>,
          ];
          if (data['caseConfigurationList'] is List<Object?>) {
            for (final group
                in data['caseConfigurationList']! as List<Object?>) {
              if (group is Map<String, Object?> &&
                  group['caseConfigurations'] is List<Object?>) {
                types.addAll(group['caseConfigurations']! as List<Object?>);
              }
            }
          }
          for (final type in types) {
            if (type is Map<String, Object?> &&
                type['uxType'] == 'Illegal Dumping Item Pickup' &&
                type['caseConfigId'] is String) {
              _caseTypeId = Uri.decodeComponent(
                type['caseConfigId']! as String,
              );
            }
          }
        }
      } on FormatException {
        return;
      }
    }
  }

  String preview(DevApiRequest request) {
    final fields = request.bodyText.isEmpty
        ? <String, String>{}
        : Uri.splitQueryString(request.bodyText);
    return const JsonEncoder.withIndent('  ').convert({
      'method': request.method,
      'destination': request.url,
      'headers': jsonDecode(request.headersText),
      if (fields.isNotEmpty) ...{
        'action': jsonDecode(fields['message']!),
        'pageURI': fields['aura.pageURI'],
        'aura.context':
            'Held in memory only; session values are not displayed.',
        'aura.token': 'null',
      },
    });
  }

  void invalidate({bool clearLocation = true}) {
    _revision++;
    _prepared = null;
    if (clearLocation) {
      _address = null;
      _addressStatus = null;
    }
    cancel();
  }
}
