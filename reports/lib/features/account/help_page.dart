import 'package:flutter/material.dart';
import '../../design/reports_design.dart';
import '../dev_api/presentation/dev_api_entry_button.dart';
import '../report/application/report_store.dart';
import '../report/data/local_report_store.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({
    super.key,
    this.initialArticle,
    this.store,
    this.fromOverview = false,
  });
  final String? initialArticle;
  final ReportStore? store;
  final bool fromOverview;
  static const icons = <String, IconData>{
    'how': Icons.article_outlined,
    'privacy': Icons.shield_outlined,
    'permissions': Icons.location_on_outlined,
    'recovery': Icons.access_time,
  };
  static Widget iconTile(IconData? icon) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: ReportsStyle.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon),
  );

  static const articles = <String, (String, String, String)>{
    'how': (
      'How reporting works',
      'From a location to your report.',
      'Choose a location, describe the items, and review your details. Illegal dumping can be submitted to the City through the native flow. No account is needed for an illegal-dumping report. Other service flows are local previews and do not create City requests.',
    ),
    'privacy': (
      'Your information & privacy',
      'Local reports and online location services.',
      'Drafts and preview receipts are kept on this device when storage is available. A real illegal-dumping submission sends report details and any selected photo to the City. Online map and address services may receive your search or coordinates. Anyone with access to this device may see saved records.',
    ),
    'permissions': (
      'Location & photo permissions',
      'Choose a location and optional photo.',
      'Location is requested when you choose to use it. Check the location before continuing. Photos are optional; avoid faces, license plates and personal documents. Manage permissions in your device settings.',
    ),
    'recovery': (
      'Drafts, receipts & interrupted sends',
      'Keep track without creating duplicates.',
      'A draft is unfinished. A demo receipt is a local preview, not a City confirmation. A real send can have an unknown outcome if interrupted. Keep your Service Request number when the City confirms a real submission. Check the original request before trying again to avoid duplicates.',
    ),
  };
  @override
  Widget build(BuildContext context) {
    final article = articles[initialArticle];
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (article == null && reportsDevModeEnabled) ...[
              Align(
                alignment: Alignment.centerRight,
                child: devApiPill(
                  context,
                  store: store ?? const LocalReportStore(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (article != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (fromOverview) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => HelpPage(store: store),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('All help topics'),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: iconTile(icons[initialArticle]),
              ),
              const SizedBox(height: 8),
              Text(
                article.$1,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(article.$2),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(article.$3),
                ),
              ),
            ] else ...[
              Text(
                'A hand when you need it',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                'Let’s clear things up.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Text('A few useful answers, without the fine print.'),
              const SizedBox(height: 16),
              for (final entry in articles.entries)
                Card(
                  child: ListTile(
                    leading: iconTile(icons[entry.key]),
                    title: Text(entry.value.$1),
                    subtitle: Text(entry.value.$2),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HelpPage(
                          initialArticle: entry.key,
                          store: store,
                          fromOverview: true,
                        ),
                      ),
                    ),
                  ),
                ),
              const Card(
                color: ReportsStyle.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What this preview can do',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Other service previews stay on this device. Illegal dumping can be sent to the City. For an immediate emergency, call 911.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
