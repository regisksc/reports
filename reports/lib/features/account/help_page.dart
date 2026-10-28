import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, this.initialArticle});
  final String? initialArticle;
  static const articles = <String, (String, String, String)>{
    'how': (
      'How reporting works',
      'From a location to your report.',
      'Choose a location, describe the items, and review your details. Illegal dumping can be submitted to the City through the native flow. Other service flows are local previews and do not create City requests.',
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
      'A draft is unfinished. A demo receipt is a local preview, not a City confirmation. A real send can have an unknown outcome if interrupted. Check the original request before trying again to avoid duplicates.',
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
            if (article != null) ...[
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
                    title: Text(entry.value.$1),
                    subtitle: Text(entry.value.$2),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HelpPage(initialArticle: entry.key),
                      ),
                    ),
                  ),
                ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Other service previews stay on this device. Illegal dumping can be sent to the City. For an immediate emergency, call 911.',
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
