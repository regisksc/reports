import '../domain/report.dart';

abstract interface class ReportStore {
  Future<ReportDraft?> loadDraft();
  Future<void> saveDraft(ReportDraft draft);
  Future<List<Report>> loadReports();
  Future<void> saveReport(Report report);
  Future<void> replaceReport(Report before, Report after);
  Future<void> discardDraft(DateTime createdAt);
  Future<void> removeLocalReceipt(Report receipt);
}
