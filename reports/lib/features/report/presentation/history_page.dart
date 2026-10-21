import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/local_record_removal.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:reports/design/reports_design.dart';
import '../application/report_store.dart';
import 'package:reports/features/report/presentation/recovery_help_page.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';

import 'report_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.client, required this.store});

  final SubmissionClient? client;
  final ReportStore store;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Report>> _reports = widget.store.loadReports();

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
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  key: const ValueKey('history-empty-panel'),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xfff7f7f7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xffe5e5e5),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xffff9600),
                        size: 44,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No reports yet.',
                        style: TextStyle(
                          color: Color(0xff3c3c3c),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Reports you save on this device will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xff777777)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ReportsContinuationHint(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final r = items[i];
                final isSubmitted = r.state == ReportState.submitted;
                return Card(
                  key: ValueKey('report-card-$i'),
                  margin: EdgeInsets.zero,
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: ReportsStyle.border,
                      width: 2,
                    ),
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
                        border: Border.all(
                          color: ReportsStyle.border,
                          width: 2,
                        ),
                      ),
                      child: r.photoPath == null
                          ? const Icon(
                              Icons.inventory_2_outlined,
                              color: ReportsStyle.orange,
                              size: 28,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(r.photoPath!),
                                fit: BoxFit.cover,
                              ),
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
                                  color: reportStatusColor(
                                    r.state,
                                  ).withAlpha(24),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: ReportsStyle.border,
                                    width: 2,
                                  ),
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
                            style: const TextStyle(
                              color: ReportsStyle.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ReportsStyle.muted,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailPage(store: widget.store,
                            report: r,
                            client: widget.client,
                          ),
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          _reports = widget.store.loadReports();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

