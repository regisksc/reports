import 'package:flutter/material.dart';
import 'service_preview_store.dart';

import 'service_preview_page.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic>? selected;
  String query = '';
  String notice = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    records = await const ServicePreviewStore().load();
    if (mounted) setState(() => loading = false);
  }

  Future<void> remove() async {
    final item = selected;
    setState(() {
      records.remove(item);
      selected = null;
    });
    final saved = await const ServicePreviewStore().remove(
      item!['id'] as String,
    );
    if (mounted && !saved) {
      setState(
        () =>
            notice = 'Changes could not be saved. They remain in this session.',
      );
    }
  }

  Future<void> follow() async {
    final item = selected!;
    final updated = {...item, 'following': item['following'] != true};
    setState(() {
      records[records.indexOf(item)] = updated;
      selected = updated;
    });
    final saved = await const ServicePreviewStore().save(updated);
    if (mounted && !saved) {
      setState(
        () =>
            notice = 'Changes could not be saved. They remain in this session.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My previews'),
      leading: selected == null
          ? null
          : BackButton(onPressed: () => setState(() => selected = null)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: selected == null
          ? [
              if (notice.isNotEmpty) Text(notice),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Find a local preview',
                ),
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase()),
              ),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (records.isEmpty)
                const Text('No local previews yet')
              else
                for (final record in records.where(
                  (item) => '${item['service']} ${item['id']}'
                      .toLowerCase()
                      .contains(query),
                ))
                  Card(
                    child: ListTile(
                      title: Text(record['service'] as String),
                      subtitle: Text(
                        '${record['step'] == 5 ? 'Local receipt' : 'Draft'} · ${record['id']}',
                      ),
                      onTap: () => setState(() => selected = record),
                    ),
                  ),
            ]
          : [
              Text(
                selected!['service'] as String,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(selected!['description'] as String? ?? ''),
              Text(selected!['address'] as String? ?? ''),
              const Text('This preview was not sent to the City.'),
              if (notice.isNotEmpty) Text(notice),
              OutlinedButton(
                onPressed: follow,
                child: Text(
                  selected!['following'] == true
                      ? 'Unfollow locally'
                      : 'Follow locally',
                ),
              ),
              if (selected!['step'] != 5)
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServicePreviewPage(
                        service: {
                          'name': selected!['service'],
                          'group': selected!['group'],
                          'evidence': selected!['evidence'],
                        },
                        draft: selected,
                      ),
                    ),
                  ),
                  child: const Text('Resume draft'),
                ),
              TextButton(
                onPressed: remove,
                child: const Text('Remove local record'),
              ),
            ],
    ),
  );
}
