import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:reports/features/dev_api/dev_api_engine.dart';
import 'package:reports/features/dev_api/presentation/dev_api_response_panels.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import '../../report/application/report_store.dart';

Future<void> showDevApiSheet(BuildContext context, {required ReportStore store, http.Client? httpClient}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => FractionallySizedBox(
        heightFactor: .94,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DevApiPage(store: store, httpClient: httpClient),
        ),
      ),
    );

class DevApiPage extends StatefulWidget {
  const DevApiPage({super.key, this.httpClient, required this.store});
  final ReportStore store;
  final http.Client? httpClient;

  @override
  State<DevApiPage> createState() => _DevApiPageState();
}

class _DevApiPageState extends State<DevApiPage> {
  static const _json = JsonEncoder.withIndent('  ');
  late final _engine = DevApiEngine(store: widget.store, client: widget.httpClient);
  final _report = TextEditingController(text: '{}');
  final _scroll = ScrollController();
  DevApiOperation _operation = DevApiOperation.bootstrap;
  bool _running = false;
  bool _reportEdited = false;
  int _runId = 0;
  String _reportSource = 'Current draft';
  String _arguments = 'No arguments previewed.';
  String _response = 'No request sent.';
  String? _feedback;
  final List<String> _events = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final draft = await widget.store.loadDraft();
      Map<String, Object?> snapshot;
      var source = 'Current draft';
      if (draft != null) {
        snapshot = draft.toJson();
      } else {
        final reports = await widget.store.loadReports();
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        snapshot = reports.isEmpty
            ? <String, Object?>{}
            : reports.first.toJson();
        source = reports.isEmpty ? 'No saved report' : 'Latest saved report';
      }
      if (mounted && !_reportEdited) {
        setState(() {
          _report.text = _json.convert({'report': snapshot});
          _reportSource = source;
        });
      }
    } on Object {
      if (mounted) setState(() => _reportSource = 'Saved data unavailable');
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    for (final controller in [_report]) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Map<String, Object?> _reportArguments() {
    final decoded = jsonDecode(_report.text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Current Report data must be a JSON object.');
    }
    final value = decoded['report'] ?? decoded;
    if (value is! Map<String, dynamic>) {
      throw const FormatException('The report must be a JSON object.');
    }
    return Map<String, Object?>.from(value);
  }

  DevApiRequest _request() =>
      _engine.preset(_operation, arguments: _reportArguments());

  void _invalidate({bool clearLocation = true}) {
    _engine.invalidate(clearLocation: clearLocation);
    _arguments = 'No arguments previewed.';
    _response = 'Previous result cleared after an input change.';
    _feedback = null;
  }

  void _record(String event) {
    _events.insert(0, event);
    if (_events.length > 12) _events.removeLast();
  }

  void _preview() {
    try {
      final preview = _engine.preview(_request());
      setState(() {
        _arguments = preview;
        _feedback = 'Arguments previewed locally. No request sent.';
      });
    } on Object catch (error) {
      setState(() => _feedback = 'Cannot preview arguments: $error');
    }
  }

  Future<void> _run() async {
    final runId = ++_runId;
    setState(() {
      _running = true;
      _feedback = null;
    });
    try {
      final request = _request();
      final response = await _engine.run(request);
      if (!mounted || runId != _runId) return;
      setState(() {
        _response =
            'HTTP ${response.statusCode} · ${response.elapsed.inMilliseconds} ms\n${response.formattedBody}';
        _feedback =
            'HTTP ${response.statusCode}. This does not prove City acceptance.';
        _record(
          '${_operation.label} · ${request.method} ${Uri.parse(request.url).path} · HTTP ${response.statusCode} · ${response.elapsed.inMilliseconds} ms',
        );
      });
    } on Object catch (error) {
      if (!mounted || runId != _runId) return;
      setState(() {
        _feedback = '$error';
        _record(
          '${_operation.label} · ${error is DevApiException ? error.kind : 'failed'}',
        );
      });
    } finally {
      if (mounted && runId == _runId) setState(() => _running = false);
    }
  }

  Report _submissionReport() {
    final values = _reportArguments();
    final quantity = values['quantity'];
    return Report.fromJson({
      ...values,
      'quantity': quantity is String ? int.tryParse(quantity) : quantity,
      'state': values['state'] ?? ReportState.notSent.name,
    });
  }

  Future<void> _reviewSubmission() async {
    final runId = ++_runId;
    setState(() {
      _running = true;
      _feedback = 'Preparing a local payload review. No report sent.';
    });
    try {
      final plan = await _engine.prepareSubmission(_submissionReport());
      if (!mounted || runId != _runId) return;
      var checked = false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: const Text('Review submitCase payload'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'This exact payload will create a real illegal dumping report with the City of Los Angeles. Reviewing sends nothing.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      plan.preview,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    CheckboxListTile(
                      value: checked,
                      onChanged: (value) => update(() => checked = value!),
                      title: const Text(
                        'I reviewed this exact destination and payload and confirm one real City submission.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep reviewing'),
              ),
              FilledButton(
                onPressed: checked ? () => Navigator.pop(context, true) : null,
                child: const Text('Confirm real submission'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || runId != _runId || confirmed != true) return;
      final result = await _engine.confirmSubmission(
        plan,
        confirmed: true,
        currentReport: _submissionReport(),
      );
      if (!mounted || runId != _runId) return;
      setState(() {
        _response = switch (result) {
          SubmissionAccepted(:final serviceRequestNumber) =>
            'City accepted Service Request $serviceRequestNumber.',
          SubmissionFailed(:final message) => message,
        };
        _feedback = _response;
        _record(
          'submitCase · ${result is SubmissionAccepted ? 'accepted' : 'not confirmed'}',
        );
      });
    } on Object catch (error) {
      if (!mounted || runId != _runId) return;
      setState(() => _feedback = '$error');
    } finally {
      if (mounted && runId == _runId) setState(() => _running = false);
    }
  }

  void _cancel() {
    _engine.cancel();
    _runId++;
    setState(() {
      _running = false;
      _feedback =
          'Cancelled locally. The server may already have received the request.';
      _record('Request cancelled');
    });
  }

  Widget _heading(String title, String chip) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: ReportsStyle.surface,
            border: Border.all(color: ReportsStyle.border, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(chip, style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    ),
  );

  Widget _editor(
    String label,
    TextEditingController controller, {
    int lines = 1,
    required String keyName,
    bool report = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: Key(keyName),
          controller: controller,
          enabled: !_running,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 4,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
          ),
          decoration: const InputDecoration(fillColor: Colors.white),
          onChanged: (_) {
            if (report) {
              _reportEdited = true;
              setState(() => _invalidate());
            }
          },
        ),
      ],
    ),
  );

  Widget get _divider => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Divider(color: ReportsStyle.border, thickness: 2),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Column(
      children: [
        Container(
          key: const Key('dev-api-header'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ReportsStyle.border, width: 2),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ReportsStyle.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'REPORTS · MYLA311',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: 'Close Dev API mode',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      side: const BorderSide(
                        color: ReportsStyle.border,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dev / API mode',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scroll,
            child: ListView(
              key: const Key('dev-api-scroll'),
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              children: [
                _heading('Request workspace', 'MyLA311 operations'),
                const Text(
                  'Opening this sheet, choosing an operation, and previewing arguments never sends a request. Run 311 request sends only the selected documented operation to MyLA311. Guest session values stay in memory.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<DevApiOperation>(
                  key: const Key('dev-api-operation'),
                  initialValue: _operation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Operation'),
                  items: [
                    for (final operation in DevApiOperation.values)
                      DropdownMenuItem(
                        value: operation,
                        child: Text(operation.label),
                      ),
                  ],
                  onChanged: _running
                      ? null
                      : (value) => setState(() {
                          _operation = value!;
                          _invalidate(clearLocation: false);
                        }),
                ),
                const SizedBox(height: 12),
                Text(_operation.detail),
                const SizedBox(height: 16),
                const SelectableText(
                  'Fixed host: https://myla311.lacity.gov\nAura route: /s/sfsites/aura',
                ),
                _divider,
                _heading('Current Report data', _reportSource),
                const Text(
                  'Read operations use these report coordinates. Inspector edits stay separate from the saved Report draft. Preparing a submit payload sends nothing.',
                ),
                const SizedBox(height: 16),
                _editor(
                  'Report · JSON object',
                  _report,
                  lines: 7,
                  keyName: 'dev-api-report',
                  report: true,
                ),
                OutlinedButton(
                  onPressed: _running ? null : _preview,
                  child: const Text('Preview arguments'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _running ? null : _reviewSubmission,
                  child: const Text('Review submitCase payload'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A separate exact-payload review and explicit confirmation are required. A prior unconfirmed attempt blocks another submission.',
                ),
                _divider,
                _heading('Prepared arguments', 'Local preview'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ReportsStyle.surface,
                    border: Border.all(color: ReportsStyle.border, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    _arguments,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
                _divider,
                DevApiResponsePanels(
                  statusLabel: _running ? 'Running' : 'Response',
                  bodyText: _response,
                  historyEntries: List.unmodifiable(_events),
                ),
              ],
            ),
          ),
        ),
        Container(
          key: const Key('dev-api-footer'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: ReportsStyle.border, width: 2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Semantics(liveRegion: true, child: Text(_feedback!)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: ReportsStyle.surface,
                        ),
                        onPressed: _running ? _cancel : null,
                        child: const Text('Cancel request'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _running ? null : _run,
                        child: Text(_running ? 'Running…' : 'Run 311 request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
