import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';

class NoSubmissionClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('Navigation does not submit Reports.');
}

class MemoryReportStore implements ReportStore {
  ReportDraft? draft;
  final reports = <Report>[];

  @override
  Future<ReportDraft?> loadDraft() async => draft;

  @override
  Future<void> saveDraft(ReportDraft value) async => draft = value;

  @override
  Future<List<Report>> loadReports() async => reports;

  @override
  Future<void> saveReport(Report report) async => reports.add(report);

  @override
  Future<void> replaceReport(Report before, Report after) async {
    reports[reports.indexOf(before)] = after;
  }

  @override
  Future<void> discardDraft(DateTime createdAt) async {
    if (draft?.createdAt == createdAt) draft = null;
  }

  @override
  Future<void> removeLocalReceipt(Report receipt) async =>
      reports.remove(receipt);
}
