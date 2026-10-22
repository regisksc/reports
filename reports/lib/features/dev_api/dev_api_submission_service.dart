part of 'dev_api_engine.dart';

mixin _DevApiSubmissionService on _DevApiState {
  Future<DevApiSubmitPlan> prepareSubmission(Report report) async {
    if (_disposed || _active != null || _submitting) {
      throw const DevApiException(
        'Wait for the active request before reviewing.',
        'busy',
      );
    }
    final revision = _revision;
    await _assertSendable(report);
    if (_fwuid == null ||
        _appId == null ||
        _caseTypeId == null ||
        _config == null ||
        _contact == null) {
      throw const DevApiException(
        'Run Guest bootstrap, request types and form questions first. No request sent.',
        'invalid',
      );
    }
    if (_config!['sCaseType'] !=
            PortalSubmissionClient.illegalDumpingRequestType ||
        report.quantity == null ||
        report.quantity! < 1 ||
        report.quantity! > 999) {
      throw const DevApiException(
        'Unsupported report details. No request sent.',
        'invalid',
      );
    }
    if (_address == null ||
        _addressStatus == null ||
        _validatedLatitude != report.latitude ||
        _validatedLongitude != report.longitude) {
      throw const DevApiException(
        'Validate the current report coordinates first. No request sent.',
        'invalid',
      );
    }
    final exact = await _submissionClient.prepareInspectorSubmission(
      report,
      fwuid: _fwuid!,
      appId: _appId!,
      caseTypeId: _caseTypeId!,
      requestCount: _requestCount,
      config: _config!,
      contact: _contact!,
      address: _address!,
      addressStatus: _addressStatus!,
    );
    if (revision != _revision) {
      throw const DevApiException(
        'Inputs changed during review. Prepare again. No request sent.',
        'invalid',
      );
    }
    final plan = DevApiSubmitPlan._(report, exact);
    _prepared = plan;
    return plan;
  }

  Future<void> _assertSendable(Report report) async {
    final saved = await store.loadReports();
    if (report.state != ReportState.notSent ||
        report.serviceRequestNumber != null ||
        saved.any(
          (row) =>
              row.state == ReportState.failed ||
              row.state == ReportState.submissionUncertain ||
              (row.createdAt == report.createdAt &&
                  row.state == ReportState.submitted),
        )) {
      throw const DevApiException(
        'A prior request is unconfirmed or already submitted. Do not resend.',
        'blocked',
      );
    }
  }

  Future<SubmissionResult> confirmSubmission(
    DevApiSubmitPlan plan, {
    required bool confirmed,
    required Report currentReport,
  }) async {
    if (!confirmed) {
      throw const DevApiException(
        'Explicit confirmation is required. No request sent.',
        'blocked',
      );
    }
    if (_disposed || _submitting || _active != null) {
      throw const DevApiException('Wait for the active request.', 'busy');
    }
    if (!identical(_prepared, plan) ||
        jsonEncode(plan.report.toJson()) !=
            jsonEncode(currentReport.toJson())) {
      throw const DevApiException(
        'The reviewed report changed. Review it again. No request sent.',
        'invalid',
      );
    }
    _submitting = true;
    try {
      await _assertSendable(currentReport);
      final attempt = Report(
        description: plan.report.description,
        latitude: plan.report.latitude,
        longitude: plan.report.longitude,
        createdAt: plan.report.createdAt,
        photoPaths: plan.report.photoPaths,
        debrisLocation: plan.report.debrisLocation,
        quantity: plan.report.quantity,
        state: ReportState.submissionUncertain,
      );
      final saved = await store.loadReports();
      final matches = saved
          .where((row) => row.createdAt == attempt.createdAt)
          .toList();
      if (matches.isEmpty) {
        await store.saveReport(attempt);
      } else {
        await store.replaceReport(matches.single, attempt);
      }
      _prepared = null;
      _requestCount++;
      final abort = Completer<void>();
      final cancelled = Completer<SubmissionResult>();
      _submitAbort = abort;
      _submitCancelled = cancelled;
      final work = _finishSubmission(plan, attempt, abort.future);
      return await Future.any([work, cancelled.future]);
    } finally {
      _submitting = false;
      _submitAbort = null;
      _submitCancelled = null;
    }
  }

  Future<SubmissionResult> _finishSubmission(
    DevApiSubmitPlan plan,
    Report attempt,
    Future<void> abort,
  ) async {
    SubmissionResult result;
    try {
      result = await _submissionClient
          .sendPrepared(plan._exact, abortTrigger: abort)
          .timeout(timeout);
    } on Object {
      result = SubmissionFailed(
        SubmissionFailureKind.uncertain,
        'The outcome is unconfirmed. Do not resend.',
      );
    }
    if (result case SubmissionAccepted(:final serviceRequestNumber)) {
      try {
        await store.replaceReport(
          attempt,
          attempt.submittedWith(serviceRequestNumber),
        );
      } on Object {
        return result;
      }
    } else if (result case SubmissionFailed(:final kind)) {
      if (kind != SubmissionFailureKind.uncertain) {
        final draft = Report(
          description: attempt.description,
          latitude: attempt.latitude,
          longitude: attempt.longitude,
          createdAt: attempt.createdAt,
          photoPaths: attempt.photoPaths,
          debrisLocation: attempt.debrisLocation,
          quantity: attempt.quantity,
        );
        await store.replaceReport(attempt, draft);
      }
    }
    return result;
  }
}
