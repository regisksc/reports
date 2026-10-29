import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/reports_design.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key, this.serviceNames = const []});

  final List<String> serviceNames;

  static const storageKey = 'reports_nearby_filters_v1';
  static String? _session;
  static bool _hasSession = false;

  static Future<void> clearSavedFilters() async {
    _session = null;
    _hasSession = true;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(storageKey)) {
      throw StateError('Nearby filters could not be cleared');
    }
  }

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final _area = TextEditingController();
  final _type = TextEditingController();
  final _neighborhood = TextEditingController();
  final _council = TextEditingController();
  String _status = 'All statuses';
  String _view = 'List';
  DateTime? _start;
  DateTime? _end;
  int _revision = 0;
  String? _clearError;

  @override
  void initState() {
    super.initState();
    for (final controller in [_area, _type, _neighborhood, _council]) {
      controller.addListener(_markEdited);
    }
    _load();
  }

  void _markEdited() => _revision++;

  Future<void> _load() async {
    final revision = _revision;
    String? saved = NearbyPage._session;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!NearbyPage._hasSession) {
        saved = prefs.getString(NearbyPage.storageKey);
      }
    } catch (_) {}
    if (!mounted || saved == null || revision != _revision) return;
    try {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      setState(() {
        _area.text = data['area'] as String? ?? '';
        _type.text = data['type'] as String? ?? '';
        _neighborhood.text = data['neighborhood'] as String? ?? '';
        _council.text = data['council'] as String? ?? '';
        _status = ['All statuses', 'Open', 'Closed'].contains(data['status'])
            ? data['status'] as String
            : 'All statuses';
        _view = data['view'] == 'Map' ? 'Map' : 'List';
        _start = DateTime.tryParse(data['start'] as String? ?? '');
        _end = DateTime.tryParse(data['end'] as String? ?? '');
      });
    } catch (_) {}
  }

  Future<void> _apply() async {
    _markEdited();
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = jsonEncode({
      'area': _area.text,
      'type': _type.text,
      'neighborhood': _neighborhood.text,
      'council': _council.text,
      'status': _status,
      'view': _view,
      'start': _start?.toIso8601String(),
      'end': _end?.toIso8601String(),
    });
    NearbyPage._session = saved;
    NearbyPage._hasSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(NearbyPage.storageKey, saved);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _clear() async {
    _markEdited();
    FocusManager.instance.primaryFocus?.unfocus();
    _area.clear();
    _type.clear();
    _neighborhood.clear();
    _council.clear();
    setState(() {
      _start = null;
      _end = null;
      _status = 'All statuses';
      _view = 'List';
    });
    try {
      await NearbyPage.clearSavedFilters();
      if (mounted) setState(() => _clearError = null);
    } on Object {
      if (mounted) {
        setState(
          () => _clearError =
              'Filters cleared for this session, but saved filters could not be removed.',
        );
      }
    }
  }

  Future<void> _date(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() {
        _markEdited();
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _area.dispose();
    _type.dispose();
    _neighborhood.dispose();
    _council.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller, String hint) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _dateField(String label, DateTime? date, bool start) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: OutlinedButton(
      onPressed: () => _date(start),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label: ${date == null ? 'Select date' : '${date.month}/${date.day}/${date.year}'}',
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nearby'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nearby reports',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Explore how nearby requests could be filtered.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ReportsStyle.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Not live. The City request map and results are not connected in this preview. The observed City view has a 2,000-record maximum.',
              ),
            ),
            const SizedBox(height: 20),
            _field('Area or address', _area, 'Enter an area or address'),
            _dateField('Start date', _start, true),
            _dateField('End date', _end, false),
            DropdownButtonFormField<String>(
              key: ValueKey('nearby-status-$_status'),
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                'All statuses',
                'Open',
                'Closed',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() {
                _markEdited();
                _status = v!;
              }),
            ),
            const SizedBox(height: 16),
            _field(
              'Request type',
              _type,
              widget.serviceNames.isEmpty
                  ? 'All services'
                  : 'All services (e.g. ${widget.serviceNames.first})',
            ),
            _field(
              'Neighborhood Council District',
              _neighborhood,
              'All districts',
            ),
            _field('Council District', _council, 'All districts'),
            DropdownButtonFormField<String>(
              key: ValueKey('nearby-view-$_view'),
              initialValue: _view,
              decoration: const InputDecoration(labelText: 'Map or list'),
              items: [
                'List',
                'Map',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() {
                _markEdited();
                _view = v!;
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _apply, child: const Text('Apply filters')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _clear,
              child: const Text('Clear filters'),
            ),
            if (_clearError != null) Text(_clearError!),
            const SizedBox(height: 24),
            Container(
              key: Key('nearby-${_view.toLowerCase()}'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ReportsStyle.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _view == 'Map' ? 'Map unavailable' : 'No live results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Location and City records are unavailable in this preview.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
