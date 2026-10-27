import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../design/reports_design.dart';
import '../../report/application/report_store.dart';
import 'dev_api_page.dart';

const reportsDevModeEnabled = bool.fromEnvironment(
  'REPORTS_DEV_MODE',
  defaultValue: kDebugMode,
);

Widget devApiPill(
  BuildContext context, {
  required ReportStore store,
  Key? key,
  bool enabled = reportsDevModeEnabled,
}) => enabled
    ? Container(
        key: key,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ReportsStyle.border, width: 2),
          boxShadow: const [
            BoxShadow(color: ReportsStyle.border, offset: Offset(0, 4)),
          ],
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ReportsStyle.ink,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            shape: const StadiumBorder(),
          ),
          onPressed: () => showDevApiSheet(context, store: store),
          child: const Text('Dev / API'),
        ),
      )
    : const SizedBox.shrink();
