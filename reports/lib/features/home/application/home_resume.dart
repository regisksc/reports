import '../../report/domain/report.dart';
import '../../report/application/report_store.dart';

class HomeResume {
  const HomeResume.draft(this.draft) : report = null;
  const HomeResume.unconfirmed(this.report) : draft = null;

  final ReportDraft? draft;
  final Report? report;
}

Future<HomeResume?> loadHomeResume(ReportStore store) async {
  final draft = await store.loadDraft();
  final reports = await store.loadReports();
  Report? latestUnconfirmed;
  for (final report in reports) {
    if ((report.state == ReportState.failed ||
            report.state == ReportState.submissionUncertain) &&
        (latestUnconfirmed == null ||
            report.createdAt.isAfter(latestUnconfirmed.createdAt))) {
      latestUnconfirmed = report;
    }
  }
  if (latestUnconfirmed != null &&
      (draft == null ||
          !draft.createdAt.isAfter(latestUnconfirmed.createdAt))) {
    return HomeResume.unconfirmed(latestUnconfirmed);
  }
  return draft == null ? null : HomeResume.draft(draft);
}

