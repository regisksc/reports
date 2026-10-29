import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reports/features/account/motion_preference_scope.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/data/local_report_store.dart';

import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/home/presentation/home_screen.dart';

class ReportApp extends StatefulWidget {
  const ReportApp({super.key, this.client, this.store});

  final SubmissionClient? client;
  final ReportStore? store;

  @override
  State<ReportApp> createState() => _ReportAppState();
}

class _ReportAppState extends State<ReportApp> with WidgetsBindingObserver {
  static const _motionKey = 'reports_device_preferences_v1';
  bool _reduceMotion = false;
  int _motionRevision = 0;
  final _motionPreference = ValueNotifier<bool>(false);
  Future<void> _motionSaves = Future<void>.value();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final _client = widget.client ?? PortalSubmissionClient();
  late final _store = widget.store ?? const LocalReportStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreMotion();
  }

  void _notice(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _restoreMotion() async {
    final revision = _motionRevision;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_motionKey) ?? false;
      if (mounted && revision == _motionRevision) {
        setState(() => _reduceMotion = saved);
        _motionPreference.value = saved;
      }
    } on Object {
      _notice(
        'Motion preference could not be loaded. Using the session setting.',
      );
    }
  }

  void _changeMotion(bool value) {
    _motionRevision++;
    setState(() => _reduceMotion = value);
    _motionPreference.value = value;
    final revision = _motionRevision;
    _motionSaves = _motionSaves.then((_) => _saveMotion(value, revision));
  }

  Future<void> _saveMotion(bool value, int revision) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(_motionKey, value)) {
        throw StateError('Could not save motion preference');
      }
    } on Object {
      if (revision == _motionRevision) {
        _notice(
          'Motion preference could not be saved. It applies for this session.',
        );
      }
    }
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionPreference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MotionPreferenceScope(
      preference: _motionPreference,
      child: MaterialApp(
        title: 'Reports',
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        theme: ReportsStyle.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                _reduceMotion ||
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .accessibilityFeatures
                    .reduceMotion ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
        home: HomeScreen(
          client: _client,
          store: _store,
          reduceMotion: _reduceMotion,
          onMotionChanged: _changeMotion,
        ),
      ),
    );
  }
}
