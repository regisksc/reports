part of 'dev_api_engine.dart';

enum DevApiOperation {
  bootstrap,
  requestTypes,
  caseTypeDetails,
  validateAddress,
  nearby,
}

extension DevApiOperationDescription on DevApiOperation {
  String get label => switch (this) {
    DevApiOperation.bootstrap => 'Guest bootstrap',
    DevApiOperation.requestTypes => 'Find Illegal Dumping Item Pickup',
    DevApiOperation.caseTypeDetails => 'Load request form questions',
    DevApiOperation.validateAddress => 'Validate report coordinates',
    DevApiOperation.nearby => 'Check nearby requests (Portal read)',
  };

  String get detail => switch (this) {
    DevApiOperation.bootstrap =>
      'Read the public shell. Guest context stays in memory.',
    DevApiOperation.requestTypes =>
      'Read the current Illegal Dumping request type.',
    DevApiOperation.caseTypeDetails =>
      'Read server-driven questions and anonymous defaults.',
    DevApiOperation.validateAddress =>
      'Validate the prepared report coordinates.',
    DevApiOperation.nearby =>
      'Read nearby requests. This does not create a request.',
  };
}

class DevApiRequest {
  const DevApiRequest({
    required this.method,
    required this.url,
    this.headersText = '{}',
    this.bodyText = '',
  });
  final String method;
  final String url;
  final String headersText;
  final String bodyText;
}

class DevApiResponse {
  DevApiResponse({
    required this.statusCode,
    required Map<String, String> headers,
    required this.body,
    required this.elapsed,
    this.requestUrl,
  }) : headers = Map.unmodifiable(headers);
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final Duration elapsed;
  final String? requestUrl;

  String get formattedBody {
    if (Uri.tryParse(requestUrl ?? '')?.path == '/s/' &&
        ((statusCode >= 200 && statusCode < 300) ||
            body.trimLeft().startsWith('<'))) {
      return const JsonEncoder.withIndent('  ').convert({
        'httpStatus': statusCode,
        'htmlCharacters': body.length,
        'fwuidFound': body.contains('fwuid'),
        'appIdFound': body.contains('APPLICATION'),
        'sessionValues':
            'Held in memory only; values are not displayed or persisted.',
      });
    }
    if (body.isEmpty) return '(Empty response body)';
    try {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(_redact(jsonDecode(body)));
    } on FormatException {
      return body.replaceAll(
        RegExp(
          r'(fwuid|authorization|cookie|token|appId)["\s:=]+[^"\s,;<]+',
          caseSensitive: false,
        ),
        '[redacted]',
      );
    }
  }
}

Object? _redact(Object? value) {
  if (value is List<Object?>) return value.map(_redact).toList();
  if (value is Map<String, Object?>) {
    return value.map(
      (key, item) => MapEntry(
        key,
        RegExp(
              r'fwuid|appId|token|authorization|cookie|APPLICATION@markup|aura.context',
              caseSensitive: false,
            ).hasMatch(key)
            ? '[redacted]'
            : _redact(item),
      ),
    );
  }
  return value;
}

class DevApiException implements Exception {
  const DevApiException(this.message, this.kind);
  final String message;
  final String kind;
  @override
  String toString() => message;
}

class DevApiSubmitPlan {
  DevApiSubmitPlan._(this.report, this._exact);
  final Report report;
  final PortalPreparedSubmission _exact;
  String get preview => const JsonEncoder.withIndent('  ').convert({
    'operation': 'X11_RI_ParentController.submitCase',
    'destination': _exact.destination,
    'method': 'POST',
    'contentType': 'application/x-www-form-urlencoded; charset=UTF-8',
    'pageURI': _exact.pageUri,
    'actionParams': jsonDecode(_exact.actionParamsJson),
  });
}
