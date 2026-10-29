import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:reports/design/reports_design.dart';
import '../application/report_store.dart';

import 'report_detail_page.dart';
import 'report_flow_page.dart';
import '../../services/service_history_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    this.client,
    required this.store,
    this.onStartReport,
  });

  final SubmissionClient? client;
  final ReportStore store;
  final VoidCallback? onStartReport;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Report>> _reports = _loadReports();
  ReportDraft? _draft;
  String _filter = 'All reports';

  Future<List<Report>> _loadReports() async {
    final reports = await widget.store.loadReports();
    final draft = await widget.store.loadDraft();
    _draft =
        draft != null &&
            reports.any((report) => report.createdAt == draft.createdAt)
        ? null
        : draft;
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your reports')),
      body: FutureBuilder<List<Report>>(
        future: _reports,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cannot load reports.'),
                    SizedBox(height: 8),
                    Text(
                      'Check MyLA311 or call 3-1-1 before submitting again. A previous submission may have reached the City.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final draft = _draft;
          final showDraft =
              draft != null && ['All reports', 'Drafts'].contains(_filter);
          final items = snap.data!.where((report) {
            return switch (_filter) {
              'Drafts' => report.state == ReportState.notSent,
              'Receipts' => report.state == ReportState.submitted,
              'Needs confirmation' =>
                report.state == ReportState.submissionUncertain ||
                    report.state == ReportState.failed,
              _ => true,
            };
          }).toList();
          final recordCount =
              (showDraft ? 1 : 0) +
              items.length +
              (items.isEmpty && !showDraft ? 1 : 0);
          return ReportsContinuationHint(
            child: ListView.builder(
              itemCount: recordCount + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'KEPT CLOSE, ON THIS DEVICE',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 16),
                        _heading(context),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final filter in [
                              'All reports',
                              'Drafts',
                              'Receipts',
                              'Needs confirmation',
                            ])
                              Semantics(
                                selected: _filter == filter,
                                child: OutlinedButton(
                                  style: ReportsStyle.raisedButtonStyle(
                                    shadowColor: ReportsStyle.border,
                                    backgroundColor: _filter == filter
                                        ? ReportsStyle.surface
                                        : Colors.white,
                                    side: BorderSide(
                                      color: _filter == filter
                                          ? ReportsStyle.ink
                                          : ReportsStyle.border,
                                      width: 2,
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => _filter = filter),
                                  child: Text(filter),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                if (index == recordCount + 1) return _otherServices();
                if (showDraft && index == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit_note),
                        title: Text(
                          draft.description.isEmpty
                              ? 'Your unfinished report'
                              : draft.description,
                        ),
                        subtitle: const Text('Draft · Saved on this device'),
                        trailing: TextButton(
                          onPressed: widget.client == null
                              ? null
                              : () => _resumeDraft(draft),
                          child: const Text('Continue'),
                        ),
                      ),
                    ),
                  );
                }
                if (items.isEmpty) return _emptyPanel();
                final reportIndex = index - (showDraft ? 2 : 1);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                  child: _reportCard(context, items[reportIndex], reportIndex),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your reports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Drafts and saved receipts, all in one place.'),
      ],
    );
    final action = FilledButton.icon(
      onPressed: widget.onStartReport,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('New report'),
    );
    if (MediaQuery.textScalerOf(context).scale(16) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 16), action],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        SizedBox(width: 130, child: action),
      ],
    );
  }

  Widget _otherServices() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'These records stay on this device. Only confirmed City receipts include a Service Request number.',
          style: TextStyle(color: ReportsStyle.muted),
        ),
        const SizedBox(height: 24),
        const Text(
          'Other service reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find local drafts and preview receipts for other services.',
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const ServiceHistoryPage()),
          ),
          child: const Text('View other service reports'),
        ),
      ],
    ),
  );

  Future<void> _resumeDraft(ReportDraft draft) async {
    await Navigator.push<Report>(
      context,
      MaterialPageRoute<Report>(
        builder: (_) => ReportFlowPage(
          store: widget.store,
          client: widget.client!,
          draft: draft,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _reports = _loadReports();
      });
    }
  }

  Widget _emptyPanel() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        key: const ValueKey('history-empty-panel'),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ReportsStyle.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ReportsStyle.border, width: 2),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: ReportsStyle.orange,
              size: 44,
            ),
            SizedBox(height: 20),
            Text(
              'No reports yet.',
              style: TextStyle(
                color: ReportsStyle.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Reports you save on this device will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ReportsStyle.muted),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _reportCard(BuildContext context, Report r, int i) {
    final isSubmitted = r.state == ReportState.submitted;
    return Card(
      key: ValueKey('report-card-$i'),
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ReportsStyle.border, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          key: ValueKey('report-thumb-$i'),
          width: 52,
          height: 56,
          decoration: BoxDecoration(
            color: ReportsStyle.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ReportsStyle.border, width: 2),
          ),
          child: r.photoPath == null
              ? const Icon(
                  Icons.inventory_2_outlined,
                  color: ReportsStyle.orange,
                  size: 28,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(r.photoPath!), fit: BoxFit.cover),
                ),
        ),
        title: Text(
          r.description.isEmpty ? 'Illegal dumping' : r.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ReportsStyle.ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    key: ValueKey('report-status-$i'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: reportStatusColor(r.state).withAlpha(24),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: ReportsStyle.border, width: 2),
                    ),
                    child: Text(
                      reportStatusLabel(r.state),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                        color: reportStatusColor(r.state),
                      ),
                    ),
                  ),
                  if (isSubmitted && r.serviceRequestNumber != null)
                    Text(
                      r.serviceRequestNumber!,
                      style: const TextStyle(
                        color: ReportsStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatReportDate(r.createdAt),
                style: const TextStyle(color: ReportsStyle.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: ReportsStyle.muted),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailPage(
                store: widget.store,
                report: r,
                client: widget.client,
              ),
            ),
          );
          if (mounted) {
            setState(() {
              _reports = _loadReports();
            });
          }
        },
      ),
    );
  }
}
