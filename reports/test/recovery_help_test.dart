import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart' as app;
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const testStore = LocalReportStore();

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = Directory(
      '.dart_tool',
    ).absolute.createTempSync('synthetic-help-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _HelpPaths(supportDirectory.path);
  });
  tearDown(() {
    PathProviderPlatform.instance = originalPaths;
    supportDirectory.deleteSync(recursive: true);
  });
  testWidgets(
    'unconfirmed recovery Help preserves the attempt when phone is unavailable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final observed = <String, Object?>{};
      final submissionClient = _NoSubmissionClient();
      final attachmentBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File('${supportDirectory.path}/synthetic-photo.png')
        ..writeAsBytesSync(attachmentBytes);
      final originalLauncher = UrlLauncherPlatform.instance;
      final launcher = _PhoneLauncher()
        ..throwFailure = false
        ..opened = false;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);
      final attempt = Report(
        description: 'Synthetic unconfirmed couch near the alley',
        latitude: 34.052235,
        longitude: -118.243683,
        createdAt: DateTime(2026, 10, 22),
        state: ReportState.submissionUncertain,
        photoPath: photo.path,
        serviceRequestNumber: 'SR-SYNTHETIC-UNCONFIRMED',
      );
      await tester.runAsync(() => testStore.saveReport(attempt));
      final marker = File('${supportDirectory.path}/submission-attempt.json');
      final before = marker.readAsStringSync();
      await tester.pumpWidget(app.ReportApp(client: submissionClient));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await _waitFor(
        tester,
        () => find.text('Help with this submission').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['heading'] = find
          .text('Submission unconfirmed')
          .evaluate()
          .length;
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['storedReference'] = find
          .text('Stored reference: SR-SYNTHETIC-UNCONFIRMED')
          .evaluate()
          .length;
      observed['coordinates'] = find
          .text('34.052235, -118.243683')
          .evaluate()
          .length;
      observed['noResend'] = find
          .textContaining('Do not resend')
          .evaluate()
          .length;
      await tester.tap(find.text('Call 311'));
      await tester.pumpAndSettle();
      observed['url'] = launcher.url;
      observed['mode'] = launcher.mode;
      observed['unavailable'] = find
          .text(
            'Phone action unavailable on this device. Call 311 or (213) 473-3231.',
          )
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      observed['submit'] = find
          .widgetWithText(FilledButton, 'Submit')
          .evaluate()
          .length;
      observed['retry'] = find
          .widgetWithText(FilledButton, 'Retry')
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['marker'] = marker.readAsStringSync();
      final reports = await tester.runAsync(testStore.loadReports);
      observed['report'] = reports!.single.toJson();
      observed['calls'] = launcher.calls;
      observed['submissionCalls'] = submissionClient.calls;
      observed['attachmentBytes'] = photo.readAsBytesSync();
      expect(observed, {
        'heading': 1,
        'description': 1,
        'storedReference': 1,
        'coordinates': 1,
        'noResend': 1,
        'url': 'tel:+12134733231',
        'mode': PreferredLaunchMode.externalApplication,
        'unavailable': 1,
        'submit': 0,
        'retry': 0,
        'marker': before,
        'report': attempt.toJson(),
        'calls': 1,
        'submissionCalls': 0,
        'attachmentBytes': attachmentBytes,
      });
    },
  );

  testWidgets(
    'unconfirmed recovery Help preserves the attempt when phone is exception',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final observed = <String, Object?>{};
      final submissionClient = _NoSubmissionClient();
      final attachmentBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File('${supportDirectory.path}/synthetic-photo.png')
        ..writeAsBytesSync(attachmentBytes);
      final originalLauncher = UrlLauncherPlatform.instance;
      final launcher = _PhoneLauncher()
        ..throwFailure = true
        ..opened = false;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);
      final attempt = Report(
        description: 'Synthetic unconfirmed couch near the alley',
        latitude: 34.052235,
        longitude: -118.243683,
        createdAt: DateTime(2026, 10, 22),
        state: ReportState.submissionUncertain,
        photoPath: photo.path,
        serviceRequestNumber: 'SR-SYNTHETIC-UNCONFIRMED',
      );
      await tester.runAsync(() => testStore.saveReport(attempt));
      final marker = File('${supportDirectory.path}/submission-attempt.json');
      final before = marker.readAsStringSync();
      await tester.pumpWidget(app.ReportApp(client: submissionClient));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await _waitFor(
        tester,
        () => find.text('Help with this submission').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['heading'] = find
          .text('Submission unconfirmed')
          .evaluate()
          .length;
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['storedReference'] = find
          .text('Stored reference: SR-SYNTHETIC-UNCONFIRMED')
          .evaluate()
          .length;
      observed['coordinates'] = find
          .text('34.052235, -118.243683')
          .evaluate()
          .length;
      observed['noResend'] = find
          .textContaining('Do not resend')
          .evaluate()
          .length;
      await tester.tap(find.text('Call 311'));
      await tester.pumpAndSettle();
      observed['url'] = launcher.url;
      observed['mode'] = launcher.mode;
      observed['unavailable'] = find
          .text(
            'Phone action unavailable on this device. Call 311 or (213) 473-3231.',
          )
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      observed['submit'] = find
          .widgetWithText(FilledButton, 'Submit')
          .evaluate()
          .length;
      observed['retry'] = find
          .widgetWithText(FilledButton, 'Retry')
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['marker'] = marker.readAsStringSync();
      final reports = await tester.runAsync(testStore.loadReports);
      observed['report'] = reports!.single.toJson();
      observed['calls'] = launcher.calls;
      observed['submissionCalls'] = submissionClient.calls;
      observed['attachmentBytes'] = photo.readAsBytesSync();
      expect(observed, {
        'heading': 1,
        'description': 1,
        'storedReference': 1,
        'coordinates': 1,
        'noResend': 1,
        'url': 'tel:+12134733231',
        'mode': PreferredLaunchMode.externalApplication,
        'unavailable': 1,
        'submit': 0,
        'retry': 0,
        'marker': before,
        'report': attempt.toJson(),
        'calls': 1,
        'submissionCalls': 0,
        'attachmentBytes': attachmentBytes,
      });
    },
  );

  testWidgets(
    'unconfirmed recovery Help preserves the attempt when phone is opened',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final observed = <String, Object?>{};
      final submissionClient = _NoSubmissionClient();
      final attachmentBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File('${supportDirectory.path}/synthetic-photo.png')
        ..writeAsBytesSync(attachmentBytes);
      final originalLauncher = UrlLauncherPlatform.instance;
      final launcher = _PhoneLauncher()
        ..throwFailure = false
        ..opened = true;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);
      final attempt = Report(
        description: 'Synthetic unconfirmed couch near the alley',
        latitude: 34.052235,
        longitude: -118.243683,
        createdAt: DateTime(2026, 10, 22),
        state: ReportState.submissionUncertain,
        photoPath: photo.path,
        serviceRequestNumber: 'SR-SYNTHETIC-UNCONFIRMED',
      );
      await tester.runAsync(() => testStore.saveReport(attempt));
      final marker = File('${supportDirectory.path}/submission-attempt.json');
      final before = marker.readAsStringSync();
      await tester.pumpWidget(app.ReportApp(client: submissionClient));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await _waitFor(
        tester,
        () => find.text('Help with this submission').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['heading'] = find
          .text('Submission unconfirmed')
          .evaluate()
          .length;
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['storedReference'] = find
          .text('Stored reference: SR-SYNTHETIC-UNCONFIRMED')
          .evaluate()
          .length;
      observed['coordinates'] = find
          .text('34.052235, -118.243683')
          .evaluate()
          .length;
      observed['noResend'] = find
          .textContaining('Do not resend')
          .evaluate()
          .length;
      await tester.tap(find.text('Call 311'));
      await tester.pumpAndSettle();
      observed['url'] = launcher.url;
      observed['mode'] = launcher.mode;
      observed['unavailable'] = find
          .text(
            'Phone action unavailable on this device. Call 311 or (213) 473-3231.',
          )
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      observed['submit'] = find
          .widgetWithText(FilledButton, 'Submit')
          .evaluate()
          .length;
      observed['retry'] = find
          .widgetWithText(FilledButton, 'Retry')
          .evaluate()
          .length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(attempt.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(attempt.description));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help with this submission'));
      await tester.pumpAndSettle();
      observed['description'] = find
          .text(attempt.description)
          .evaluate()
          .length;
      observed['marker'] = marker.readAsStringSync();
      final reports = await tester.runAsync(testStore.loadReports);
      observed['report'] = reports!.single.toJson();
      observed['calls'] = launcher.calls;
      observed['submissionCalls'] = submissionClient.calls;
      observed['attachmentBytes'] = photo.readAsBytesSync();
      expect(observed, {
        'heading': 1,
        'description': 1,
        'storedReference': 1,
        'coordinates': 1,
        'noResend': 1,
        'url': 'tel:+12134733231',
        'mode': PreferredLaunchMode.externalApplication,
        'unavailable': 0,
        'submit': 0,
        'retry': 0,
        'marker': before,
        'report': attempt.toJson(),
        'calls': 1,
        'submissionCalls': 0,
        'attachmentBytes': attachmentBytes,
      });
    },
  );
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  if (!ready()) {
    throw StateError('Expected recovery UI did not appear');
  }
  await tester.pumpAndSettle();
}

class _HelpPaths extends PathProviderPlatform {
  _HelpPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _NoSubmissionClient implements SubmissionClient {
  int calls = 0;
  @override
  Future<SubmissionResult> send(Report report) {
    calls++;
    throw StateError('Recovery Help must not submit');
  }
}

class _PhoneLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  String? url;
  PreferredLaunchMode? mode;
  bool opened = false;
  bool throwFailure = false;
  int calls = 0;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    mode = options.mode;
    calls++;
    if (throwFailure) {
      throw StateError('Synthetic unavailable telephone action');
    }
    return opened;
  }
}
