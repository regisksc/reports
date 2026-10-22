import 'package:flutter/foundation.dart';
import '../domain/report.dart';
import '../domain/submission_contract.dart';
import 'report_store.dart';

class ReportFlowController extends ChangeNotifier {
  ReportFlowController({
    required this.store,
    required this.client,
    ReportDraft? draft,
    this.onAccepted,
  }) : draftCreatedAt = draft?.createdAt ?? DateTime.now() {
    if (draft != null) {
      description = draft.description;
      quantityText = draft.quantity;
      debris = draft.debrisLocation;
      photoPaths.addAll(draft.photoPaths);
      if (draft.latitude != null && draft.longitude != null) {
        position = (latitude: draft.latitude!, longitude: draft.longitude!);
      }
      step = position == null ? 0 : draft.step.clamp(0, 4);
    }
  }
  final ReportStore store;
  final SubmissionClient client;
  final ValueChanged<Report>? onAccepted;
  final DateTime draftCreatedAt;
  final List<String> photoPaths = [];
  ({double latitude, double longitude})? position;
  String description = '';
  String quantityText = '';
  String? debris;
  bool sending = false;
  String? failure;
  String? serviceRequestNumber;
  Report? savedDraft;
  bool checkingStorage = true;
  bool submissionUncertain = false;
  Report? uncertainAttempt;
  bool storageBlocked = false;
  bool draftSaveFailed = false;
  int draftSaveVersion = 0;
  int step = 0;
  bool editingReview = false;
  bool _disposed = false;

  void _update(VoidCallback update) {
    update();
    notifyListeners();
  }

  void changeStep(int value, {bool fromReview = false}) {
    _update(() {
      step = value;
      editingReview = fromReview;
    });
    persistDraft();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> checkSavedAttempts() async {
    try {
      final reports = await store.loadReports();
      if (!_disposed) {
        _update(() {
          uncertainAttempt = null;
          for (final report in reports) {
            if (report.createdAt != draftCreatedAt) continue;
            if (report.state == ReportState.submissionUncertain ||
                report.state == ReportState.failed) {
              uncertainAttempt ??= report;
            }
            if (report.createdAt == draftCreatedAt) {
              if (report.state == ReportState.submitted) {
                serviceRequestNumber = report.serviceRequestNumber;
                storageBlocked = serviceRequestNumber == null;
              } else if (report.state == ReportState.notSent) {
                savedDraft = report;
              }
            }
          }
          submissionUncertain = uncertainAttempt != null;
          checkingStorage = false;
        });
      }
    } on Object {
      if (!_disposed) {
        _update(() {
          checkingStorage = false;
          storageBlocked = true;
        });
      }
    }
  }

  bool get locked =>
      checkingStorage ||
      sending ||
      submissionUncertain ||
      storageBlocked ||
      serviceRequestNumber != null;

  int? get quantity {
    final n = int.tryParse(quantityText);
    return n != null && n >= 1 && n <= 999 ? n : null;
  }

  String? get quantityError => quantityText.isEmpty || quantity != null
      ? null
      : 'Enter a whole number from 1 to 999';

  bool get canSubmit =>
      !locked &&
      position != null &&
      description.trim().isNotEmpty &&
      debris != null &&
      quantity != null;

  bool get canContinue =>
      !locked &&
      switch (step) {
        0 => position != null,
        1 => debris != null && quantity != null,
        3 => description.trim().isNotEmpty,
        _ => true,
      };

  Future<void> persistDraft() async {
    if (locked) return;
    final version = ++draftSaveVersion;
    bool saved;
    try {
      await store.saveDraft(
        ReportDraft(
          createdAt: draftCreatedAt,
          description: description,
          latitude: position?.latitude,
          longitude: position?.longitude,
          photoPaths: photoPaths,
          debrisLocation: debris,
          quantity: quantityText,
          step: step,
        ),
      );
      saved = true;
    } on Object {
      saved = false;
    }
    if (!_disposed && version == draftSaveVersion && !locked) {
      _update(() => draftSaveFailed = !saved);
    }
  }

  Future<void> submit() async {
    if (!canSubmit) return;
    _update(() {
      sending = true;
      failure = null;
    });
    final attempt = Report(
      description: description.trim(),
      latitude: position!.latitude,
      longitude: position!.longitude,
      createdAt: savedDraft?.createdAt ?? draftCreatedAt,
      photoPaths: photoPaths,
      debrisLocation: debris,
      quantity: quantity,
      state: ReportState.submissionUncertain,
    );
    try {
      if (savedDraft == null) {
        await store.saveReport(attempt);
      } else {
        await store.replaceReport(savedDraft!, attempt);
      }
      savedDraft = attempt;
    } on Object {
      if (!_disposed) {
        _update(() {
          sending = false;
          storageBlocked = true;
        });
      }
      return;
    }
    SubmissionResult result;
    try {
      result = await client.send(attempt);
    } on Object {
      result = SubmissionFailed(
        SubmissionFailureKind.uncertain,
        'The submission outcome could not be confirmed.',
      );
    }
    switch (result) {
      case SubmissionAccepted(:final serviceRequestNumber):
        var retained = false;
        try {
          await store.replaceReport(
            attempt,
            attempt.submittedWith(serviceRequestNumber),
          );
          retained = true;
        } on Object {
          storageBlocked = true;
        }
        if (!_disposed) {
          _update(() {
            sending = false;
            serviceRequestNumber = serviceRequestNumber;
            failure = null;
          });
          if (retained) {
            onAccepted?.call(attempt.submittedWith(serviceRequestNumber));
          }
        }
      case SubmissionFailed(:final kind, :final message):
        submissionUncertain = kind == SubmissionFailureKind.uncertain;
        uncertainAttempt = submissionUncertain ? attempt : null;
        if (!submissionUncertain) {
          final draft = Report(
            description: attempt.description,
            latitude: attempt.latitude,
            longitude: attempt.longitude,
            createdAt: attempt.createdAt,
            photoPaths: attempt.photoPaths,
            debrisLocation: attempt.debrisLocation,
            quantity: attempt.quantity,
          );
          try {
            await store.replaceReport(attempt, draft);
            savedDraft = draft;
          } on Object {
            storageBlocked = true;
          }
        }
        if (!_disposed) {
          _update(() {
            sending = false;
            failure = message;
          });
        }
    }
  }
}
