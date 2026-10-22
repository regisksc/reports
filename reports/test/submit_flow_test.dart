import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const testStore = LocalReportStore();

const _locationChannel = MethodChannel('flutter.baseflow.com/geolocator');

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp('reports-flow-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _locationChannel,
          (call) async => switch (call.method) {
            'isLocationServiceEnabled' => true,
            'checkPermission' || 'requestPermission' => 2,
            'getCurrentPosition' => {
              'latitude': 34.052235,
              'longitude': -118.243683,
              'timestamp': 1787000000000,
            },
            _ => null,
          },
        );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_locationChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  testWidgets(
    'the native form saves an attempt before sending and shows its receipt',
    (tester) async {
      final reply = Completer<SubmissionResult>();
      final client = _ReplyClient(reply.future);
      await _openReport(tester, client);
      await _fillReport(tester);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      });
      await _waitFor(tester, () => client.requested.isCompleted);

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final pending = await tester.runAsync(testStore.loadReports);
      expect(pending!.single.state, ReportState.submissionUncertain);

      reply.complete(SubmissionAccepted('SR-NATIVE-1'));
      await _waitFor(
        tester,
        () => find.text('SR-NATIVE-1').evaluate().isNotEmpty,
      );

      expect(find.text('SR-NATIVE-1'), findsOneWidget);
      final stored = await tester.runAsync(testStore.loadReports);
      expect(stored!.single.toJson(), {
        'description': 'Couch and mattress on sidewalk',
        'latitude': 34.052235,
        'longitude': -118.243683,
        'createdAt': pending.single.createdAt.toIso8601String(),
        'photoPath': null,
        'debrisLocation': 'Curb',
        'quantity': 3,
        'state': 'submitted',
        'serviceRequestNumber': 'SR-NATIVE-1',
      });
    },
  );

  for (final kind in [
    SubmissionFailureKind.network,
    SubmissionFailureKind.sessionExpired,
    SubmissionFailureKind.rejected,
  ]) {
    testWidgets(
      'a known $kind failure allows corrected retry in the same saved row',
      (tester) async {
        final client = _SequenceClient([
          SubmissionFailed(kind, 'Please correct this request.'),
          SubmissionAccepted('SR-CORRECTED'),
        ]);
        await _openReport(tester, client);
        await _fillReport(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await _waitFor(tester, () => find.text('Retry').evaluate().isNotEmpty);
        final before = await tester.runAsync(testStore.loadReports);
        expect(before!.single.state, ReportState.notSent);
        await tester.tap(find.text('Edit Items'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('report-quantity')), '4');
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Description'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('report-description')),
          'Corrected couch location',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await _waitFor(
          tester,
          () => find.text('SR-CORRECTED').evaluate().isNotEmpty,
        );

        final after = await tester.runAsync(testStore.loadReports);
        expect(after!.single.createdAt, before.single.createdAt);
        expect(after.single.description, 'Corrected couch location');
        expect(after.single.quantity, 4);
        expect(after.single.state, ReportState.submitted);
        expect(after.single.serviceRequestNumber, 'SR-CORRECTED');
      },
    );
  }

  testWidgets(
    'an unconfirmed submission cannot retry while a fresh report remains usable after restart',
    (tester) async {
      final client = _SequenceClient([
        SubmissionFailed(
          SubmissionFailureKind.uncertain,
          'The City reply was lost.',
        ),
        SubmissionAccepted('UNEXPECTED-SECOND-SR'),
      ]);
      await _openReport(tester, client);
      await _fillReport(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _waitFor(
        tester,
        () => find.textContaining('Do not resend.').evaluate().isNotEmpty,
      );

      expect(find.text('Retry'), findsNothing);
      expect(find.text('Submit'), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Edit Description'),
            )
            .onPressed,
        isNull,
      );
      final stored = await tester.runAsync(testStore.loadReports);
      expect(stored!.single.state, ReportState.submissionUncertain);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start a report'));
      await _waitFor(
        tester,
        () =>
            find
                .widgetWithText(OutlinedButton, 'Use my location')
                .evaluate()
                .isNotEmpty &&
            tester
                    .widget<OutlinedButton>(
                      find.widgetWithText(OutlinedButton, 'Use my location'),
                    )
                    .onPressed !=
                null,
      );
      expect(find.textContaining('Do not resend.'), findsNothing);
      expect(find.text('Submit'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await _openReport(tester, client);
      expect(find.textContaining('Do not resend.'), findsNothing);
      expect(find.text('Submit'), findsNothing);
      expect(find.text('UNEXPECTED-SECOND-SR'), findsNothing);
    },
  );

  testWidgets(
    'a failed attempt write prevents dispatch and explains the storage block',
    (tester) async {
      await _openReport(
        tester,
        _SequenceClient([SubmissionAccepted('UNEXPECTED-SR')]),
      );
      await _fillReport(tester);
      SharedPreferencesStorePlatform.instance = _FailingStore();

      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _waitFor(
        tester,
        () => find.textContaining('Sending is blocked.').evaluate().isNotEmpty,
      );

      expect(find.text('UNEXPECTED-SR'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Submit'), findsNothing);
      final stored = await tester.runAsync(testStore.loadReports);
      expect(stored!.single.state, ReportState.submissionUncertain);
    },
  );

  testWidgets('unavailable saved submission state blocks a new form', (
    tester,
  ) async {
    PathProviderPlatform.instance = _SupportPath(null);

    await _openReport(
      tester,
      _SequenceClient([SubmissionAccepted('UNEXPECTED-SR')]),
    );

    expect(find.textContaining('Sending is blocked.'), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Use my location'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('an unexpected client error retains an unconfirmed attempt', (
    tester,
  ) async {
    await _openReport(tester, _ThrowingClient());
    await _fillReport(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await _waitFor(
      tester,
      () => find.textContaining('Do not resend.').evaluate().isNotEmpty,
    );

    expect(find.text('Retry'), findsNothing);
    final stored = await tester.runAsync(testStore.loadReports);
    expect(stored!.single.state, ReportState.submissionUncertain);
  });

  for (final result in [
    SubmissionAccepted('SR-KEEP-THIS'),
    SubmissionFailed(SubmissionFailureKind.rejected, 'Outside city limits'),
  ]) {
    testWidgets(
      'a failed ${result.runtimeType} write keeps further sends blocked',
      (tester) async {
        final reply = Completer<SubmissionResult>();
        final client = _ReplyClient(reply.future);
        await _openReport(tester, client);
        await _fillReport(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await _waitFor(tester, () => client.requested.isCompleted);
        SharedPreferencesStorePlatform.instance = _FailingStore();

        reply.complete(result);
        await _waitFor(
          tester,
          () =>
              find.textContaining('Sending is blocked.').evaluate().isNotEmpty,
        );

        expect(find.text('Retry'), findsNothing);
        expect(find.text('Submit'), findsNothing);
        if (result is SubmissionAccepted) {
          expect(find.text('SR-KEEP-THIS'), findsOneWidget);
        }
        SharedPreferences.setMockInitialValues({});
        final stored = await tester.runAsync(testStore.loadReports);
        expect(stored!.single.state, ReportState.submissionUncertain);
      },
    );
  }
}

Future<void> _openReport(WidgetTester tester, SubmissionClient client) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 2000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ReportApp(client: client));
  await tester.tap(find.text('Start a report'));
  await _waitFor(
    tester,
    () =>
        find.text('Where did you spot it?').evaluate().isNotEmpty &&
        (tester
                    .widget<OutlinedButton>(
                      find.widgetWithText(OutlinedButton, 'Use my location'),
                    )
                    .onPressed !=
                null ||
            find.textContaining('Sending is blocked.').evaluate().isNotEmpty ||
            find.textContaining('Do not resend.').evaluate().isNotEmpty),
  );
}

Future<void> _fillReport(WidgetTester tester) async {
  await tester.tap(find.text('Use my location'));
  await tester.pumpAndSettle();
  await _continue(tester);
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Curb').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('report-quantity')), '3');
  await _continue(tester);
  await tester.tap(find.text('Skip photo'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('report-description')),
    'Couch and mattress on sidewalk',
  );
  await _continue(tester);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 1000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  expect(ready(), isTrue);
  await tester.pump(const Duration(milliseconds: 400));
}

class _ReplyClient implements SubmissionClient {
  _ReplyClient(this.reply);

  final Future<SubmissionResult> reply;
  final requested = Completer<void>();

  @override
  Future<SubmissionResult> send(Report report) {
    requested.complete();
    return reply;
  }
}

class _SequenceClient implements SubmissionClient {
  _SequenceClient(this.replies);

  final List<SubmissionResult> replies;

  @override
  Future<SubmissionResult> send(Report report) async => replies.removeAt(0);
}

class _ThrowingClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) async =>
      throw StateError('Unexpected interrupted response');
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String? path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
