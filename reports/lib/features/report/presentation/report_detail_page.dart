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

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({
    super.key,
    required this.report,
    this.client,
    required this.store,
  });

  final Report report;
  final ReportStore store;
  final SubmissionClient? client;

  Future<void> _correct(BuildContext context) async {
    try {
      final retained = await store.loadDraft();
      final draft = retained?.createdAt == report.createdAt
          ? retained!
          : ReportDraft(
              createdAt: report.createdAt,
              description: report.description,
              latitude: report.latitude,
              longitude: report.longitude,
              photoPaths: report.photoPaths,
              debrisLocation: report.debrisLocation,
              quantity: report.quantity?.toString() ?? '',
              step: 4,
            );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportFlowPage(
            store: store,
            client: client ?? PortalSubmissionClient(),
            draft: draft,
          ),
        ),
      );
      if (context.mounted) Navigator.pop(context);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the saved report. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = report.photoPath;
    final isSubmitted = report.state == ReportState.submitted;
    final srNumber = report.serviceRequestNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: ReportsContinuationHint(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(photo), height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              key: const ValueKey('report-receipt'),
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: ReportsStyle.border, width: 2),
              ),
              color: reportStatusColor(report.state).withAlpha(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportStatusLabel(report.state),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: reportStatusColor(report.state),
                      ),
                    ),
                    if (report.state == ReportState.submissionUncertain ||
                        report.state == ReportState.failed) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecoveryHelpPage(report: report),
                          ),
                        ),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Help with this submission'),
                      ),
                    ],
                    if (isSubmitted && srNumber != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Service Request: $srNumber',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (srNumber.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(text: srNumber),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Service Request number copied.',
                                        ),
                                      ),
                                    );
                                  }
                                } on Object {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not copy the Service Request number. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copy number'),
                            ),
                            Builder(
                              builder: (shareContext) => OutlinedButton.icon(
                                onPressed: () async {
                                  final box =
                                      shareContext.findRenderObject()
                                          as RenderBox;
                                  try {
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        subject:
                                            'MyLA311 Service Request $srNumber',
                                        text:
                                            'MyLA311 illegal-dumping receipt\n'
                                            'Service Request: $srNumber\n'
                                            'Status: Submitted\n'
                                            'Description: ${report.description}\n'
                                            'Coordinates: ${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}\n'
                                            '${report.debrisLocation == null ? '' : 'Debris location: ${report.debrisLocation}\n'}'
                                            '${report.quantity == null ? '' : 'Item count: ${report.quantity}\n'}'
                                            'Created: ${formatReportDate(report.createdAt)}',
                                        sharePositionOrigin:
                                            box.localToGlobal(Offset.zero) &
                                            box.size,
                                      ),
                                    );
                                  } on Object {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Receipt could not be shared. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.ios_share),
                                label: const Text('Share receipt'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (isSubmitted && srNumber?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => confirmLocalRemoval(
                  context,
                  title: 'Remove local receipt?',
                  remove: () => store.removeLocalReceipt(report),
                ),
                child: const Text('Remove local receipt'),
              ),
            ],
            if (report.state == ReportState.notSent) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _correct(context),
                child: const Text('Correct report'),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              key: const ValueKey('report-detail-panel'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ReportsStyle.border, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(report.description),
                  const SizedBox(height: 20),
                  if (report.debrisLocation != null) ...[
                    const Text(
                      'Debris location',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(report.debrisLocation!),
                    const SizedBox(height: 20),
                  ],
                  if (report.quantity != null) ...[
                    const Text(
                      'Item count',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text('${report.quantity}'),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Coordinates',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Date created',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(formatReportDate(report.createdAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
