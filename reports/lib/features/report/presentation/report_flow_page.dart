import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/local_record_removal.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reports/features/report/domain/report.dart';
import '../application/report_store.dart';
import '../application/report_flow_controller.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/presentation/report_presentation.dart';
import 'package:reports/features/report/presentation/location_map.dart';
import 'package:reports/features/report/presentation/recovery_help_page.dart';

part 'report_flow_steps.dart';

class ReportFlowPage extends StatefulWidget {
  const ReportFlowPage({
    super.key,
    required this.client,
    required this.store,
    this.draft,
    this.onAccepted,
  });
  final SubmissionClient client;
  final ReportStore store;
  final ReportDraft? draft;
  final ValueChanged<Report>? onAccepted;
  @override
  State<ReportFlowPage> createState() => _ReportFlowPageState();
}

class _ReportFlowPageState extends State<ReportFlowPage> {
  late final ReportFlowController _controller;
  String? _photoError;
  bool _pickingPhoto = false;
  String? _locationError;
  bool _locating = false;
  final _desc = TextEditingController();
  final _qty = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ReportFlowController(store: widget.store, client: widget.client, draft: widget.draft, onAccepted: widget.onAccepted);
    _desc.text = _controller.description;
    _qty.text = _controller.quantityText;
    _desc.addListener(_syncInputs);
    _qty.addListener(_syncInputs);
    _controller.addListener(_onChanged);
    _controller.checkSavedAttempts();
  }
  void _syncInputs() {
    _controller.description = _desc.text;
    _controller.quantityText = _qty.text;
  }
  void _onChanged() {
    if (mounted) setState(() {});
  }
  void _update(VoidCallback update) => setState(update);

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _scroll.dispose();
    _desc.dispose();
    _qty.dispose();
    super.dispose();
  }

  List<String> get _photoPaths => _controller.photoPaths;
  ({double latitude, double longitude})? get _position => _controller.position;
  set _position(({double latitude, double longitude})? value) => _controller.position = value;
  String? get _debris => _controller.debris;
  set _debris(String? value) => _controller.debris = value;
  bool get _sending => _controller.sending;
  String? get _failure => _controller.failure;
  String? get _serviceRequestNumber => _controller.serviceRequestNumber;
  Report? get _savedDraft => _controller.savedDraft;
  bool get _submissionUncertain => _controller.submissionUncertain;
  Report? get _uncertainAttempt => _controller.uncertainAttempt;
  bool get _storageBlocked => _controller.storageBlocked;
  bool get _draftSaveFailed => _controller.draftSaveFailed;
  int get _step => _controller.step;
  bool get _editingReview => _controller.editingReview;
  DateTime get _draftCreatedAt => _controller.draftCreatedAt;
  bool get _locked => _controller.locked;
  String? get _quantityError => _controller.quantityError;
  int? get _quantity => _controller.quantity;
  bool get _canSubmit => _controller.canSubmit;
  bool get _canContinue => _controller.canContinue;

  void _changeStep(int step, {bool fromReview = false}) {
    FocusScope.of(context).unfocus();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _controller.changeStep(step, fromReview: fromReview);
  }
  Future<void> _persistDraft() => _controller.persistDraft();
  Future<void> _submit() => _controller.submit();

  Future<void> _pickPhoto(ImageSource source) async {
    if (_locked || _pickingPhoto || _photoPaths.length >= 3) return;
    setState(() => _pickingPhoto = true);
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (x == null || !mounted || _locked) return;
      final support = await getApplicationSupportDirectory();
      await support.create(recursive: true);
      final directory = await support.createTemp('photo-');
      final photo = await File(
        x.path,
      ).copy('${directory.path}/photo.${x.path.split('.').last}');
      if (mounted && !_locked) {
        setState(() {
          _photoPaths.add(photo.path);
          _photoError = null;
        });
        await _persistDraft();
      }
    } on Object {
      if (mounted) {
        setState(
          () => _photoError = 'Photo could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        if (mounted) {
          setState(() {
            _locationError =
                'Location services are off. Turn them on in Settings, then tap Use my location again.';
          });
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _locationError =
                'Location permission is denied. Allow it in Settings, then tap Use my location again.',
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = (latitude: pos.latitude, longitude: pos.longitude));
        await _persistDraft();
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = _serviceRequestNumber;
    final failure = _failure;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 400);
    const labels = ['Location', 'Items', 'Photos', 'Details', 'Review'];
    const headings = [
      'Where did you spot it?',
      'What’s been left behind?',
      'Have a photo?',
      'Add a little detail.',
      'Looking good? Take a look.',
    ];
    const descriptions = [
      'Choose the dumped items’ location on the map or use your current location.',
      'Tell us where the items are and how many need collecting.',
      'A photo can help tell the story. This step is optional.',
      'Describe the items and add a nearby landmark or access note.',
      'Check the details before sending your report to MyLA311.',
    ];
    return PopScope<Object?>(
      canPop: (_step == 0 && !_editingReview) || _locked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_locked) {
          _changeStep(_editingReview ? 4 : _step - 1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if ((_step > 0 || _editingReview) && !_locked) {
                _changeStep(_editingReview ? 4 : _step - 1);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (!_locked && _savedDraft == null)
              IconButton(
                tooltip: 'Discard draft',
                onPressed: () => confirmLocalRemoval(
                  context,
                  title: 'Discard draft?',
                  remove: () => widget.store.discardDraft(_draftCreatedAt),
                ),
                icon: const Icon(Icons.close),
              ),
          ],
          title: const Text('Report illegal dumping'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ReportsContinuationHint(
                child: ListView(
                  key: ValueKey(_submissionUncertain),
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      'Step ${_step + 1} of 5 · ${labels[_step]}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: (_step + 1) / 5),
                      duration: duration,
                      builder: (context, value, child) =>
                          LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                            semanticsLabel: 'Report progress',
                          ),
                    ),
                    const SizedBox(height: 28),
                    if (_submissionUncertain) ...[
                      if (failure != null) ...[
                        Text(
                          'Submission unconfirmed: $failure',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _notice(
                        'A submission may already have reached MyLA311. Do not resend. Check My reports and contact 311 before making another request.',
                      ),
                      if (_uncertainAttempt case final attempt?)
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecoveryHelpPage(report: attempt),
                            ),
                          ),
                          icon: const Icon(Icons.help_outline),
                          label: const Text('Help with this submission'),
                        ),

                      const SizedBox(height: 20),
                    ],
                    if (_storageBlocked) ...[
                      _notice(
                        'Your report could not be saved safely. Sending is blocked. Keep any Service Request number shown and check My reports.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_draftSaveFailed && !_locked) ...[
                      _notice(
                        'Draft could not be saved. Keep this report open to avoid losing your changes.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (number != null)
                      _receipt(number)
                    else ...[
                      Text(
                        labels[_step].toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: ReportsStyle.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        headings[_step],
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 13),
                      Text(
                        descriptions[_step],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ReportsStyle.muted,
                        ),
                      ),
                      const SizedBox(height: 25),
                      AnimatedSwitcher(
                        duration: duration,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) =>
                            ReportsContentTransition(
                              animation: animation,
                              child: child,
                            ),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        child: SizedBox(
                          key: ValueKey(_step),
                          width: double.infinity,
                          child: switch (_step) {
                            0 => _locationStep(),
                            1 => _itemsStep(),
                            2 => _photoStep(),
                            3 => _detailsStep(),
                            _ => _reviewStep(),
                          },
                        ),
                      ),
                      if (failure != null &&
                          !_submissionUncertain &&
                          !_storageBlocked) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Not sent: $failure',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 4),
                        const Text('Your report is saved as not sent.'),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar:
            number != null || _submissionUncertain || _storageBlocked
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    13,
                    20,
                    12 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: ReportsStyle.border, width: 2),
                    ),
                  ),
                  child: FilledButton(
                    onPressed: _step == 4
                        ? (_canSubmit ? _submit : null)
                        : (_canContinue
                              ? () =>
                                    _changeStep(_editingReview ? 4 : _step + 1)
                              : null),
                    child: _sending
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _editingReview
                                ? 'Save changes'
                                : _step == 4
                                ? (_savedDraft == null ? 'Submit' : 'Retry')
                                : (_step == 2 && _photoPaths.isEmpty
                                      ? 'Skip photo'
                                      : 'Continue'),
                          ),
                  ),
                ),
              ),
      ),
    );
  }

}
