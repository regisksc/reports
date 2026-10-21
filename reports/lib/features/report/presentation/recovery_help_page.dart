import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:reports/design/reports_design.dart';

class RecoveryHelpPage extends StatefulWidget {
  const RecoveryHelpPage({super.key, required this.report});
  final Report report;

  @override
  State<RecoveryHelpPage> createState() => _RecoveryHelpPageState();
}

class _RecoveryHelpPageState extends State<RecoveryHelpPage> {
  bool _phoneUnavailable = false;

  Future<void> _call311() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse('tel:+12134733231'),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (mounted) setState(() => _phoneUnavailable = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      appBar: AppBar(title: const Text('Help with this submission')),
      body: ReportsContinuationHint(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Submission unconfirmed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: reportStatusColor(report.state),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do not resend this report. MyLA311 may already have created a Service Request. Ask 311 to check before making another request.',
            ),
            const SizedBox(height: 24),
            Text(report.description),
            const SizedBox(height: 8),
            Text(
              '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
            ),
            if (report.serviceRequestNumber != null) ...[
              const SizedBox(height: 8),
              Text('Stored reference: ${report.serviceRequestNumber}'),
            ],
            const SizedBox(height: 24),
            const Text('City of Los Angeles: 311 or (213) 473-3231.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _call311,
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Call 311'),
            ),
            if (_phoneUnavailable) ...[
              const SizedBox(height: 16),
              const Text(
                'Phone action unavailable on this device. Call 311 or (213) 473-3231.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
