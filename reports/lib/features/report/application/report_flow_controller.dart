import 'dart:async';

import 'package:flutter/foundation.dart';
import '../domain/report.dart';
import '../domain/illegal_dumping_catalog.dart';
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
      itemFamily = draft.itemFamily;
      items = List.unmodifiable(draft.items);
      quantityText = draft.quantity;
      debris = draft.debrisLocation;
      photoPaths.addAll(draft.photoPaths);
      if (draft.latitude != null && draft.longitude != null) {
        position = (latitude: draft.latitude!, longitude: draft.longitude!);
      }
      contact =
          draft.contact ??
          (draft.flowVersion < 2 ? const ReportContact(anonymous: true) : null);
      rememberContact = draft.rememberContact;
      final resumedStep = draft.flowVersion < 2 && draft.step == 4
          ? 5
          : draft.step;
      step = position == null ? 0 : resumedStep.clamp(0, 5);
    }
  }
  final ReportStore store;
  final SubmissionClient client;
  final ValueChanged<Report>? onAccepted;
  final DateTime draftCreatedAt;
  final List<String> photoPaths = [];
  ({double latitude, double longitude})? position;
  String description = '';
  String? itemFamily = "I'm not sure";
  List<ReportItem> items = const [];
  IllegalDumpingCatalog? itemCatalog;
  String? itemCatalogError;
  String quantityText = '';
  String? debris;
  ReportContact? contact;
  bool rememberContact = false;
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
  Future<void> _draftQueue = Future<void>.value();
  int _pendingDraftWrites = 0;
  bool get hasPendingDraftWrites => _pendingDraftWrites > 0;
  int step = 0;
  bool editingReview = false;
  bool _disposed = false;

  void _update(VoidCallback update) {
    update();
    notifyListeners();
  }

  Future<void> loadItemCatalog() async {
    try {
      final catalog = await IllegalDumpingCatalog.load();
      if (!_disposed) {
        _update(() {
          itemCatalog = catalog;
          itemCatalogError = null;
        });
      }
    } on Object {
      if (!_disposed) {
        _update(() => itemCatalogError = 'Item choices could not be loaded.');
      }
    }
  }

  void updateItems(String family, List<ReportItem> selection) {
    _update(() {
      itemFamily = family;
      items = List.unmodifiable(selection);
    });
    persistDraft();
  }

  bool get _itemsValid => itemFamily == null
      ? items.isEmpty && debris != null && quantity != null
      : itemCatalog?.validSelection(itemFamily!, items) ?? false;

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

  ReportContact? get _safeContact => contact?.anonymous == true
      ? const ReportContact(anonymous: true)
      : contact;

  bool _validContactEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  String? get contactEmailError {
    final current = contact;
    if (current == null ||
        current.anonymous ||
        current.email.trim().isEmpty ||
        _validContactEmail(current.email)) {
      return null;
    }
    return 'Enter a valid email address.';
  }

  bool get contactValid =>
      contact != null &&
      (contact!.anonymous ||
          (contact!.firstName.trim().isNotEmpty &&
              contact!.lastName.trim().isNotEmpty &&
              _validContactEmail(contact!.email)));

  bool get canSubmit =>
      !locked && position != null && _itemsValid && contactValid;

  bool get canContinue =>
      !locked &&
      switch (step) {
        0 => position != null,
        1 => _itemsValid,
        4 => contactValid,
        _ => true,
      };

  Future<void> flushDraftWrites() => _draftQueue;

  Future<void> persistDraft() async {
    if (locked) return;
    final version = ++draftSaveVersion;
    final draft = ReportDraft(
      createdAt: draftCreatedAt,
      description: description,
      latitude: position?.latitude,
      longitude: position?.longitude,
      photoPaths: photoPaths,
      debrisLocation: debris,
      quantity: quantityText,
      step: step,
      flowVersion: 2,
      contact: _safeContact,
      rememberContact: rememberContact,
      itemFamily: itemFamily,
      items: items,
    );
    final previous = _draftQueue;
    _pendingDraftWrites++;
    if (_pendingDraftWrites == 1 && !_disposed) notifyListeners();
    final finished = Completer<void>();
    _draftQueue = finished.future;
    bool saved;
    try {
      await previous;
      await store.saveDraft(draft);
      saved = true;
    } on Object {
      saved = false;
    } finally {
      _pendingDraftWrites--;
      finished.complete();
      if (_pendingDraftWrites == 0 && !_disposed) notifyListeners();
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
    await flushDraftWrites();
    if (_disposed) return;
    final attempt = Report(
      description: description.trim(),
      latitude: position!.latitude,
      longitude: position!.longitude,
      createdAt: savedDraft?.createdAt ?? draftCreatedAt,
      photoPaths: photoPaths,
      debrisLocation: debris,
      quantity: quantity,
      state: ReportState.submissionUncertain,
      contact: _safeContact,
      itemFamily: itemFamily,
      items: items,
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
            this.serviceRequestNumber = serviceRequestNumber;
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
            contact: attempt.contact,
            itemFamily: attempt.itemFamily,
            items: attempt.items,
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
