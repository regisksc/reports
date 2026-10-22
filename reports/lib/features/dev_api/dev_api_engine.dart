import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import '../report/application/report_store.dart';

part 'dev_api_contracts.dart';
part 'dev_api_read_session.dart';
part 'dev_api_submission_service.dart';

const _origin = 'https://myla311.lacity.gov';
const _auraPath = '/s/sfsites/aura';
const _contentType = 'application/x-www-form-urlencoded; charset=UTF-8';
const _classes = {
  'fetchInitialDetails': 'X11_H_ParentController',
  'fetchCaseTypeDetails': 'X11_RI_ParentController',
  'validateAddress': 'LA_AddressController',
  'getRelatedCaseLst': 'X11_RI_ParentController',
};

abstract class _DevApiState {
  _DevApiState({
    http.Client? client,
    required this.timeout,
    required this.store,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;
  final ReportStore store;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  Completer<void>? _abort;
  Completer<DevApiResponse>? _active;
  Timer? _timer;
  bool _disposed = false;
  String? _fwuid;
  String? _appId;
  String? _caseTypeId;
  int _requestCount = 0;
  int _revision = 0;
  Map<String, Object?>? _config;
  Map<String, Object?>? _contact;
  Map<String, Object?>? _address;
  String? _addressStatus;
  double? _validatedLatitude;
  double? _validatedLongitude;
  DevApiSubmitPlan? _prepared;
  bool _submitting = false;
  Completer<void>? _submitAbort;
  Completer<SubmissionResult>? _submitCancelled;
  late final _submissionClient = PortalSubmissionClient(httpClient: _client);

  void cancel();
  void _stop(DevApiException error);
}

class DevApiEngine extends _DevApiState
    with _DevApiReadSession, _DevApiSubmissionService {
  DevApiEngine({
    super.client,
    super.timeout = const Duration(seconds: 60),
    required super.store,
  });

  @override
  void _stop(DevApiException error) {
    final active = _active;
    if (active == null) return;
    _abort!.complete();
    _timer?.cancel();
    _timer = null;
    _active = null;
    _abort = null;
    active.completeError(error);
  }

  @override
  void cancel() {
    _stop(
      const DevApiException(
        'Canceled locally. The server may already have received the read.',
        'cancelled',
      ),
    );
    if (_submitAbort != null && !_submitAbort!.isCompleted) {
      _submitAbort!.complete();
    }
    if (_submitCancelled != null && !_submitCancelled!.isCompleted) {
      _submitCancelled!.complete(
        SubmissionFailed(
          SubmissionFailureKind.uncertain,
          'Canceled locally. The server may already have received the request. Do not resend.',
        ),
      );
    }
  }

  void dispose() {
    cancel();
    _disposed = true;
    if (_ownsClient) _client.close();
  }
}
