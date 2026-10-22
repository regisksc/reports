import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reports/features/report/domain/report.dart';

import '../application/report_store.dart';

class LocalReportStore implements ReportStore {
  const LocalReportStore();

  static const _key = 'reports_v2';
  static const _draftKey = 'report_draft_v1';

  @override
  Future<ReportDraft?> loadDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final row = preferences.getString(_draftKey);
    if (row == null) return null;
    final draft = ReportDraft.fromJson(jsonDecode(row) as Map<String, dynamic>);
    final reports = await loadReports();
    return reports.any(
          (report) =>
              report.createdAt == draft.createdAt &&
              report.state != ReportState.notSent,
        )
        ? null
        : draft;
  }

  @override
  Future<void> saveDraft(ReportDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_draftKey, jsonEncode(draft.toJson()))) {
      throw StateError('Could not save the draft.');
    }
  }

  Report? _decodeRow(String row) {
    try {
      return Report.fromJson(jsonDecode(row) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<List<Report>> loadReports() async {
    final preferences = await SharedPreferences.getInstance();
    final rows = preferences.getStringList(_key) ?? [];
    final reports = rows.map(_decodeRow).whereType<Report>().toList();
    for (final marker in await _attemptMarkers()) {
      final attempt = Report.fromJson(
        jsonDecode(await marker.readAsString()) as Map<String, dynamic>,
      );
      if (attempt.state != ReportState.submissionUncertain) {
        throw const FormatException('Invalid submission attempt marker');
      }
      final hasReceipt = reports.any(
        (report) =>
            report.createdAt == attempt.createdAt &&
            report.state == ReportState.submitted &&
            report.serviceRequestNumber?.trim().isNotEmpty == true,
      );
      if (!hasReceipt) {
        reports.removeWhere((report) => report.createdAt == attempt.createdAt);
        reports.add(attempt);
      }
    }
    return reports.reversed.toList();
  }

  Future<File> _attemptMarker() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/submission-attempt.json');
  }

  Future<void> _recordAttempt(Report report) async {
    var marker = await _attemptMarker();
    if (await marker.exists()) {
      final previous = Report.fromJson(
        jsonDecode(await marker.readAsString()) as Map<String, dynamic>,
      );
      if (previous.createdAt != report.createdAt) {
        marker = File(
          '${marker.parent.path}/submission-attempt-${report.createdAt.microsecondsSinceEpoch}.json',
        );
      }
    }
    await marker.create(exclusive: true);
    await marker.writeAsString(jsonEncode(report.toJson()), flush: true);
  }

  Future<List<File>> _attemptMarkers() async {
    final marker = await _attemptMarker();
    return marker.parent
        .list(followLinks: false)
        .where(
          (entry) =>
              entry is File &&
              RegExp(
                r'^submission-attempt(?:-\d+)?\.json$',
              ).hasMatch(entry.uri.pathSegments.last),
        )
        .cast<File>()
        .toList();
  }

  @override
  Future<void> saveReport(Report report) async {
    if (report.state == ReportState.submissionUncertain) {
      await _recordAttempt(report);
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = preferences.getStringList(_key) ?? [];
    rows.add(jsonEncode(report.toJson()));
    if (!await preferences.setStringList(_key, rows)) {
      throw StateError('Could not save the report.');
    }
  }

  @override
  Future<void> replaceReport(Report before, Report after) async {
    if (after.state == ReportState.submissionUncertain) {
      await _recordAttempt(after);
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = preferences.getStringList(_key) ?? [];
    final row = jsonEncode(after.toJson());
    final index = rows.indexWhere(
      (row) => _decodeRow(row)?.createdAt == before.createdAt,
    );
    if (index < 0) {
      rows.add(row);
    } else {
      rows[index] = row;
    }
    if (!await preferences.setStringList(_key, rows)) {
      throw StateError('Could not save the report.');
    }
    if (before.state == ReportState.submissionUncertain &&
        after.state != ReportState.submissionUncertain) {
      for (final marker in await _attemptMarkers()) {
        final attempt = Report.fromJson(
          jsonDecode(await marker.readAsString()) as Map<String, dynamic>,
        );
        if (attempt.createdAt == before.createdAt) await marker.delete();
      }
    }
  }

  @override
  Future<void> discardDraft(DateTime createdAt) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final reports = await loadReports();
    if (reports.any(
      (report) =>
          report.createdAt == createdAt &&
          (report.state == ReportState.submissionUncertain ||
              report.state == ReportState.failed),
    )) {
      throw StateError('An unconfirmed submission cannot be removed.');
    }
    final row = preferences.getString(_draftKey);
    if (row == null ||
        ReportDraft.fromJson(
              jsonDecode(row) as Map<String, dynamic>,
            ).createdAt !=
            createdAt) {
      return;
    }
    if (!await preferences.remove(_draftKey)) {
      await preferences.reload();
      throw StateError('Could not remove the draft.');
    }
  }

  @override
  Future<void> removeLocalReceipt(Report receipt) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final reports = await loadReports();
    if (!reports.any(
      (report) =>
          report.createdAt == receipt.createdAt &&
          report.state == ReportState.submitted &&
          report.serviceRequestNumber?.trim().isNotEmpty == true &&
          report.serviceRequestNumber == receipt.serviceRequestNumber,
    )) {
      throw StateError('Only a confirmed local receipt can be removed.');
    }
    await discardDraft(receipt.createdAt);
    final rows = preferences.getStringList(_key) ?? [];
    rows.removeWhere((row) => _decodeRow(row)?.createdAt == receipt.createdAt);
    if (!await preferences.setStringList(_key, rows)) {
      await preferences.reload();
      throw StateError('Could not remove the local receipt.');
    }
  }
}
