import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/material.dart';
import 'package:reports/features/report/domain/report.dart';

String reportStatusLabel(ReportState state) => switch (state) {
  ReportState.submitted => 'Submitted',
  ReportState.notSent => 'Not sent',
  ReportState.failed ||
  ReportState.submissionUncertain => 'Submission unconfirmed',
};

Color reportStatusColor(ReportState state) => switch (state) {
  ReportState.submitted => const Color(0xff166534),
  ReportState.notSent => const Color(0xff3c3c3c),
  ReportState.failed ||
  ReportState.submissionUncertain => const Color(0xff92400e),
};

final tz.Location _losAngeles = _loadLosAngeles();

tz.Location _loadLosAngeles() {
  tzdata.initializeTimeZones();
  return tz.getLocation('America/Los_Angeles');
}

String formatReportDate(DateTime timestamp) {
  final local = tz.TZDateTime.from(timestamp, _losAngeles);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'AM' : 'PM';
  final offset = local.timeZoneOffset.inMinutes;
  final offsetHours = (offset.abs() ~/ 60).toString().padLeft(2, '0');
  final offsetMinutes = (offset.abs() % 60).toString().padLeft(2, '0');
  return '$month/$day/${local.year} · $hour:$minute $period '
      '${local.timeZoneName} (UTC-$offsetHours:$offsetMinutes)';
}
