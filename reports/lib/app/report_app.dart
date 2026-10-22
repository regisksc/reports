import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:flutter/material.dart';
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
  bool _reduceMotion = false;
  late final _client = widget.client ?? PortalSubmissionClient();
  late final _store = widget.store ?? const LocalReportStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reports',
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
        onMotionChanged: (value) => setState(() => _reduceMotion = value),
      ),
    );
  }
}
