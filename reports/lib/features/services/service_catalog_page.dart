import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'service_preview_page.dart';

class ServiceCatalogPage extends StatefulWidget {
  const ServiceCatalogPage({super.key, required this.onIllegalDumping});

  final VoidCallback onIllegalDumping;

  @override
  State<ServiceCatalogPage> createState() => _ServiceCatalogPageState();
}

class _ServiceCatalogPageState extends State<ServiceCatalogPage> {
  late final Future<List<Map<String, dynamic>>> _catalog = _load();
  String _query = '';
  String? _group;

  Future<List<Map<String, dynamic>>> _load() async {
    final json = await rootBundle.loadString('assets/service_catalog.json');
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  void open(Map<String, dynamic> service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicePreviewPage(
          service: service,
          onIllegalDumping: service['name'] == 'Illegal Dumping Item Pickup'
              ? widget.onIllegalDumping
              : null,
        ),
      ),
    );
  }

  Widget row(String title, String subtitle, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton(
      onPressed: action,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title), if (subtitle.isNotEmpty) Text(subtitle)],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Services')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _catalog,
      builder: (context, snapshot) {
        final services = snapshot.data ?? [];
        final query = _query.trim().toLowerCase();
        final groups = services.map((item) => item['group'] as String).toSet();
        final filtered = services.where(
          (item) => _group != null
              ? item['group'] == _group
              : '${item['name']} ${item['group']}'.toLowerCase().contains(
                  query,
                ),
        );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_group != null)
              TextButton(
                onPressed: () => setState(() => _group = null),
                child: const Text('All services'),
              ),
            if (_group != null)
              Text(_group!, style: Theme.of(context).textTheme.headlineMedium),
            if (_group == null)
              Text(
                'Services',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            Text(
              _group == null
                  ? 'Find the right place to start. Browse by category or search by name.'
                  : 'Choose the service that best matches your concern.',
            ),
            if (_group == null)
              TextField(
                decoration: const InputDecoration(labelText: 'Search services'),
                onChanged: (value) => setState(() => _query = value),
              ),
            if (_group == null && query.isEmpty)
              for (final group in groups)
                row(
                  group,
                  '${services.where((item) => item['group'] == group).length} ${services.where((item) => item['group'] == group).length == 1 ? 'service' : 'services'}',
                  () => setState(() => _group = group),
                )
            else
              for (final service in filtered)
                row(
                  service['name'] as String,
                  _group == null ? service['group'] as String : '',
                  () => open(service),
                ),
            if (_group == null && query.isNotEmpty && filtered.isEmpty)
              const Text('No services found'),
          ],
        );
      },
    ),
  );
}
