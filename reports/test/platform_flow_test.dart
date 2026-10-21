import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart' as app;
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';


const testStore = LocalReportStore();

Finder _homeResumeContinueButton() => find.descendant(
  of: find.byKey(const Key('home-resume-card')),
  matching: find.text('Continue'),
);

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;
  late ImagePickerPlatform originalCamera;
  late GeolocatorPlatform originalLocation;
  late _Camera camera;
  late _Location location;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp(
      'reports-platform-',
    );
    originalPaths = PathProviderPlatform.instance;
    originalCamera = ImagePickerPlatform.instance;
    originalLocation = GeolocatorPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
    camera = _Camera();
    location = _Location();
    ImagePickerPlatform.instance = camera;
    GeolocatorPlatform.instance = location;
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    ImagePickerPlatform.instance = originalCamera;
    GeolocatorPlatform.instance = originalLocation;
    await supportDirectory.delete(recursive: true);
  });

  testWidgets('local receipt removal can be cancelled without changing records', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);
    final observed = <String, Object?>{};
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final photo = File('${supportDirectory.path}/synthetic-shared-removal.png')
      ..writeAsBytesSync(bytes);
    Report receipt(String description, DateTime createdAt, String sr) => Report(
      description: description,
      latitude: 34.05,
      longitude: -118.24,
      createdAt: createdAt,
      photoPath: photo.path,
    ).submittedWith(sr);
    final removed = receipt(
      'Synthetic receipt to remove',
      DateTime(2026, 10, 1),
      'SR-SYNTHETIC-REMOVE',
    );
    final retained = receipt(
      'Synthetic receipt to retain',
      DateTime(2026, 10, 2),
      'C-04955177',
    );
    await tester.runAsync(() => testStore.saveReport(removed));
    await tester.runAsync(() => testStore.saveReport(retained));
    await testStore.saveDraft(
      ReportDraft(
        createdAt: removed.createdAt,
        description: 'Synthetic hidden confirmed Draft',
        latitude: 34.05,
        longitude: -118.24,
        photoPath: photo.path,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
      ),
    );
    await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
    await tester.pumpAndSettle();
    observed['initialDrafts'] = _homeResumeContinueButton().evaluate().length;
    await tester.tap(find.text('View saved reports'));
    await _waitFor(
      tester,
      () => find.text(removed.description).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(removed.description));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove local receipt'));
    await tester.pumpAndSettle();
    observed['cancellationNotice'] = find
        .textContaining('does not cancel')
        .evaluate()
        .length;
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    observed['cancelledReportCount'] = (await tester.runAsync(
      testStore.loadReports,
    ))!.length;
    expect(observed, {
      'initialDrafts': 0,
      'cancellationNotice': 1,
      'cancelledReportCount': 2,
    });
  });

  testWidgets('a failed Draft removal leaves the local receipt recoverable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);
    final observed = <String, Object?>{};
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final photo = File('${supportDirectory.path}/synthetic-shared-removal.png')
      ..writeAsBytesSync(bytes);
    Report receipt(String description, DateTime createdAt, String sr) => Report(
      description: description,
      latitude: 34.05,
      longitude: -118.24,
      createdAt: createdAt,
      photoPath: photo.path,
    ).submittedWith(sr);
    final removed = receipt(
      'Synthetic receipt to remove',
      DateTime(2026, 10, 1),
      'SR-SYNTHETIC-REMOVE',
    );
    final retained = receipt(
      'Synthetic receipt to retain',
      DateTime(2026, 10, 2),
      'C-04955177',
    );
    await tester.runAsync(() => testStore.saveReport(removed));
    await tester.runAsync(() => testStore.saveReport(retained));
    await testStore.saveDraft(
      ReportDraft(
        createdAt: removed.createdAt,
        description: 'Synthetic hidden confirmed Draft',
        latitude: 34.05,
        longitude: -118.24,
        photoPath: photo.path,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
      ),
    );
    await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
    await tester.pumpAndSettle();
    observed['initialDrafts'] = _homeResumeContinueButton().evaluate().length;
    await tester.tap(find.text('View saved reports'));
    await _waitFor(
      tester,
      () => find.text(removed.description).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(removed.description));
    await tester.pumpAndSettle();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures();
    final data = await tester.runAsync(
      SharedPreferencesStorePlatform.instance.getAll,
    );
    final store = _RemovalStore(data!)
      ..failRemoval = true
      ..failRows = false;
    SharedPreferencesStorePlatform.instance = store;
    await tester.tap(find.text('Remove local receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await _waitFor(
      tester,
      () => find
          .text('Could not remove this local record. Try again.')
          .evaluate()
          .isNotEmpty,
    );
    observed['notice'] = find
        .text('Could not remove this local record. Try again.')
        .evaluate()
        .length;
    final records = await tester.runAsync(testStore.loadReports);
    observed['reports'] = records!.map((report) => report.toJson()).toList();
    observed['photo'] = photo.readAsBytesSync();
    expect(observed, {
      'initialDrafts': 0,
      'notice': 1,
      'reports': [retained.toJson(), removed.toJson()],
      'photo': bytes,
    });
  });

  testWidgets('a failed Receipt write leaves the local receipt recoverable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: true);
    final observed = <String, Object?>{};
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final photo = File('${supportDirectory.path}/synthetic-shared-removal.png')
      ..writeAsBytesSync(bytes);
    Report receipt(String description, DateTime createdAt, String sr) => Report(
      description: description,
      latitude: 34.05,
      longitude: -118.24,
      createdAt: createdAt,
      photoPath: photo.path,
    ).submittedWith(sr);
    final removed = receipt(
      'Synthetic receipt to remove',
      DateTime(2026, 10, 1),
      'SR-SYNTHETIC-REMOVE',
    );
    final retained = receipt(
      'Synthetic receipt to retain',
      DateTime(2026, 10, 2),
      'C-04955177',
    );
    await tester.runAsync(() => testStore.saveReport(removed));
    await tester.runAsync(() => testStore.saveReport(retained));
    await testStore.saveDraft(
      ReportDraft(
        createdAt: removed.createdAt,
        description: 'Synthetic hidden confirmed Draft',
        latitude: 34.05,
        longitude: -118.24,
        photoPath: photo.path,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
      ),
    );
    await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
    await tester.pumpAndSettle();
    observed['initialDrafts'] = _homeResumeContinueButton().evaluate().length;
    await tester.tap(find.text('View saved reports'));
    await _waitFor(
      tester,
      () => find.text(removed.description).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(removed.description));
    await tester.pumpAndSettle();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures();
    final data = await tester.runAsync(
      SharedPreferencesStorePlatform.instance.getAll,
    );
    final store = _RemovalStore(data!)
      ..failRemoval = false
      ..failRows = true;
    SharedPreferencesStorePlatform.instance = store;
    await tester.tap(find.text('Remove local receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await _waitFor(
      tester,
      () => find
          .text('Could not remove this local record. Try again.')
          .evaluate()
          .isNotEmpty,
    );
    observed['notice'] = find
        .text('Could not remove this local record. Try again.')
        .evaluate()
        .length;
    final records = await tester.runAsync(testStore.loadReports);
    observed['reports'] = records!.map((report) => report.toJson()).toList();
    observed['photo'] = photo.readAsBytesSync();
    expect(observed, {
      'initialDrafts': 0,
      'notice': 1,
      'reports': [retained.toJson(), removed.toJson()],
      'photo': bytes,
    });
  });

  testWidgets(
    'removing a local receipt cannot revive its hidden Draft after restart',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(reduceMotion: true);
      final observed = <String, Object?>{};
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File(
        '${supportDirectory.path}/synthetic-shared-removal.png',
      )..writeAsBytesSync(bytes);
      Report receipt(String description, DateTime createdAt, String sr) =>
          Report(
            description: description,
            latitude: 34.05,
            longitude: -118.24,
            createdAt: createdAt,
            photoPath: photo.path,
          ).submittedWith(sr);
      final removed = receipt(
        'Synthetic receipt to remove',
        DateTime(2026, 10, 1),
        'SR-SYNTHETIC-REMOVE',
      );
      final retained = receipt(
        'Synthetic receipt to retain',
        DateTime(2026, 10, 2),
        'C-04955177',
      );
      await tester.runAsync(() => testStore.saveReport(removed));
      await tester.runAsync(() => testStore.saveReport(retained));
      await testStore.saveDraft(
        ReportDraft(
          createdAt: removed.createdAt,
          description: 'Synthetic hidden confirmed Draft',
          latitude: 34.05,
          longitude: -118.24,
          photoPath: photo.path,
          debrisLocation: 'Curb',
          quantity: '1',
          step: 4,
        ),
      );
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.pumpAndSettle();
      observed['initialDrafts'] = _homeResumeContinueButton().evaluate().length;
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(removed.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(removed.description));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove local receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await _waitFor(
        tester,
        () =>
            find.text(retained.description).evaluate().isNotEmpty &&
            find.text(removed.description).evaluate().isEmpty,
        step: const Duration(milliseconds: 16),
      );
      observed['removedReceipt'] = find
          .text(removed.description)
          .evaluate()
          .length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.pumpAndSettle();
      observed['draftAfterReceiptRemoval'] = find
          .text('Continue')
          .evaluate()
          .length;
      final records = await tester.runAsync(testStore.loadReports);
      observed['retainedReports'] = records!
          .map((report) => report.toJson())
          .toList();
      observed['photoAfterReceiptRemoval'] = await tester.runAsync(
        photo.readAsBytes,
      );
      expect(observed, {
        'initialDrafts': 0,
        'removedReceipt': 0,
        'draftAfterReceiptRemoval': 0,
        'retainedReports': [retained.toJson()],
        'photoAfterReceiptRemoval': bytes,
      });
    },
  );

  testWidgets(
    'discarding an unfinished Draft survives restart and retains its photo',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(reduceMotion: true);
      final observed = <String, Object?>{};
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File(
        '${supportDirectory.path}/synthetic-shared-removal.png',
      )..writeAsBytesSync(bytes);
      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 3),
        description: 'Synthetic unfinished removal',
        latitude: 34.05,
        longitude: -118.24,
        photoPath: photo.path,
        debrisLocation: 'Curb',
        quantity: '1',
        step: 4,
      );
      await testStore.saveDraft(draft);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await _waitFor(
        tester,
        () => _homeResumeContinueButton().evaluate().isNotEmpty,
      );
      await tester.tap(_homeResumeContinueButton());
      await _waitFor(
        tester,
        () => find.byTooltip('Discard draft').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Discard draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await _waitFor(
        tester,
        () => find.text('Start a report').evaluate().isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.pumpAndSettle();
      observed['draftAfterDiscard'] = _homeResumeContinueButton()
          .evaluate()
          .length;
      observed['photoAfterDraftRemoval'] = await tester.runAsync(
        photo.readAsBytes,
      );
      expect(observed, {
        'draftAfterDiscard': 0,
        'photoAfterDraftRemoval': bytes,
      });
    },
  );

  testWidgets(
    'an unconfirmed local record stays protected while new reports remain usable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(reduceMotion: true);
      final observed = <String, Object?>{};
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File(
        '${supportDirectory.path}/synthetic-shared-removal.png',
      )..writeAsBytesSync(bytes);
      final uncertain = Report(
        description: 'Synthetic protected attempt',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 4),
        photoPath: photo.path,
        state: ReportState.submissionUncertain,
      );
      await tester.runAsync(() => testStore.saveReport(uncertain));
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(uncertain.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(uncertain.description));
      await tester.pumpAndSettle();
      observed['protectedReceiptRemoval'] = find
          .text('Remove local receipt')
          .evaluate()
          .length;
      observed['protectedDraftRemoval'] = find
          .text('Discard draft')
          .evaluate()
          .length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
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
      observed['protectedSends'] = find
          .widgetWithText(FilledButton, 'Submit')
          .evaluate()
          .length;
      observed['markerExists'] = File(
        '${supportDirectory.path}/submission-attempt.json',
      ).existsSync();
      observed['protectedReports'] = (await tester.runAsync(
        testStore.loadReports,
      ))!.map((report) => report.toJson()).toList();
      expect(observed, {
        'protectedReceiptRemoval': 0,
        'protectedDraftRemoval': 0,
        'protectedSends': 0,
        'markerExists': true,
        'protectedReports': [uncertain.toJson()],
      });
    },
  );

  testWidgets(
    'a known Not sent report reopens, retains corrections after restart and retries in its original row',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final observed = <String, Object?>{};
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final photo = File(
        '${supportDirectory.path}/synthetic-known-not-sent.png',
      )..writeAsBytesSync(bytes);
      final photos = [
        photo,
        for (var i = 2; i <= 3; i++)
          File('${supportDirectory.path}/synthetic-known-$i.png')
            ..writeAsBytesSync([...bytes, i]),
      ];
      final retained = Report(
        description: 'Synthetic known Not sent couch',
        latitude: 34.052235,
        longitude: -118.243683,
        createdAt: DateTime(2026, 10, 20, 10),
        photoPaths: photos.map((file) => file.path).toList(),
        debrisLocation: 'Curb',
        quantity: 2,
        state: ReportState.notSent,
      );
      final receipt = Report(
        description: 'Synthetic retained exact receipt',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 1),
      ).submittedWith('C-04955177');
      final preferences = await SharedPreferences.getInstance();
      final legacy = retained.toJson()..remove('serviceRequestNumber');
      await preferences.setStringList('reports_v2', [
        jsonEncode(receipt.toJson()),
        jsonEncode(legacy),
      ]);
      final requests = <http.Request>[];
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return _syntheticPortalReply(request);
        }),
      );
      await tester.pumpWidget(app.ReportApp(client: client));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(retained.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(retained.description));
      await tester.pumpAndSettle();
      await preferences.setString(
        'report_draft_v1',
        'invalid synthetic Draft JSON',
      );
      await tester.tap(find.text('Correct report'));
      await _waitFor(
        tester,
        () => find
            .text('Could not open the saved report. Try again.')
            .evaluate()
            .isNotEmpty,
      );
      await preferences.remove('report_draft_v1');
      await tester.tap(find.text('Correct report'));
      await _waitFor(
        tester,
        () =>
            find.text('Edit Description').evaluate().isNotEmpty &&
            find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty &&
            tester
                    .widget<FilledButton>(
                      find.widgetWithText(FilledButton, 'Retry'),
                    )
                    .onPressed !=
                null,
      );
      observed['initialItems'] = tester
          .widget<Text>(find.text('2 items · Curb'))
          .data;
      observed['initialPhoto'] = tester
          .widget<Text>(find.text('3 photos attached'))
          .data;
      await tester.tap(find.text('Edit Photo'));
      await tester.pumpAndSettle();
      final images = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as FileImage).file)
          .toList();
      observed['previewBytes'] = await tester.runAsync(
        () async => [for (final image in images) await image.readAsBytes()],
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Description'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic corrected retained couch',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      observed['requestsBeforeRestart'] = requests.length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: client));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(retained.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(retained.description));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Correct report'));
      await _waitFor(
        tester,
        () =>
            find.text('Edit Description').evaluate().isNotEmpty &&
            find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty &&
            tester
                    .widget<FilledButton>(
                      find.widgetWithText(FilledButton, 'Retry'),
                    )
                    .onPressed !=
                null,
      );
      observed['resumedDescription'] = tester
          .widget<Text>(find.text('Synthetic corrected retained couch'))
          .data;
      observed['resumedPhoto'] = tester
          .widget<Text>(find.text('3 photos attached'))
          .data;
      observed['requestsBeforeRetry'] = requests.length;
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await _waitFor(
        tester,
        () => find.text('SR-SYNTHETIC-DRAFT').evaluate().isNotEmpty,
      );
      final reports = await tester.runAsync(testStore.loadReports);
      observed['reports'] = reports!.map((report) => report.toJson()).toList();
      final actions = requests
          .where((request) => request.method == 'POST')
          .map(
            (request) =>
                (jsonDecode(
                          Uri.splitQueryString(request.body)['message']!,
                        )['actions']
                        as List)
                    .single,
          );
      final submitted =
          actions.singleWhere(
                (action) => action['params']['method'] == 'submitCase',
              )['params']['params']
              as Map;
      observed['payloadDescription'] =
          (submitted['sCaseQuestionJSON'] as String).contains(
            'Synthetic corrected retained couch',
          );
      observed['payloadPhoto'] = [
        for (final file in photos)
          (submitted['sFileLinks'] as String).contains(
            base64Encode(file.readAsBytesSync()),
          ),
      ];
      observed['anonymous'] = jsonDecode(
        submitted['sObjContact'] as String,
      )['isAnonymously'];
      observed['durablePhotoBytes'] = await tester.runAsync(photo.readAsBytes);
      await tester.pageBack();
      await _waitFor(
        tester,
        () => find
            .text('Synthetic corrected retained couch')
            .evaluate()
            .isNotEmpty,
      );
      observed['returnHeading'] = tester
          .widget<Text>(find.text('Your reports'))
          .data;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: client));
      await tester.pumpAndSettle();
      observed['draftAfterSubmission'] = find
          .text('Continue')
          .evaluate()
          .length;
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find
            .text('Synthetic corrected retained couch')
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text('Synthetic corrected retained couch'));
      await tester.pumpAndSettle();
      observed['correctionAfterSubmission'] = find
          .text('Correct report')
          .evaluate()
          .length;
      observed['receiptText'] = tester
          .widget<Text>(find.text('Service Request: SR-SYNTHETIC-DRAFT'))
          .data;
      expect(observed, {
        'initialItems': '2 items · Curb',
        'initialPhoto': '3 photos attached',
        'previewBytes': photos.map((file) => file.readAsBytesSync()).toList(),
        'requestsBeforeRestart': 0,
        'resumedDescription': 'Synthetic corrected retained couch',
        'resumedPhoto': '3 photos attached',
        'requestsBeforeRetry': 0,
        'reports': [
          {
            ...retained.toJson(),
            'description': 'Synthetic corrected retained couch',
            'state': 'submitted',
            'serviceRequestNumber': 'SR-SYNTHETIC-DRAFT',
          },
          receipt.toJson(),
        ],
        'payloadDescription': true,
        'payloadPhoto': [true, true, true],
        'anonymous': true,
        'durablePhotoBytes': bytes,
        'returnHeading': 'Your reports',
        'draftAfterSubmission': 0,
        'correctionAfterSubmission': 0,
        'receiptText': 'Service Request: SR-SYNTHETIC-DRAFT',
      });
    },
  );

  for (final state in [
    ReportState.submitted,
    ReportState.submissionUncertain,
    ReportState.failed,
  ]) {
    testWidgets('a stale correction action preserves a $state lock', (
      tester,
    ) async {
      final report = Report(
        description: 'Synthetic stale correction',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 21),
        debrisLocation: 'Curb',
        quantity: 1,
      );
      await tester.runAsync(() => testStore.saveReport(report));
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text(report.description).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(report.description));
      await tester.pumpAndSettle();
      final protected = Report(
        description: report.description,
        latitude: report.latitude,
        longitude: report.longitude,
        createdAt: report.createdAt,
        debrisLocation: report.debrisLocation,
        quantity: report.quantity,
        state: state,
        serviceRequestNumber: state == ReportState.submitted
            ? 'SR-SYNTHETIC-PROTECTED'
            : null,
      );
      await tester.runAsync(() => testStore.replaceReport(report, protected));
      await tester.tap(find.text('Correct report'));
      await _waitFor(
        tester,
        () => state == ReportState.submitted
            ? find.text('SR-SYNTHETIC-PROTECTED').evaluate().isNotEmpty
            : find.textContaining('Do not resend.').evaluate().isNotEmpty ||
                  (find
                          .widgetWithText(FilledButton, 'Retry')
                          .evaluate()
                          .isNotEmpty &&
                      tester
                              .widget<FilledButton>(
                                find.widgetWithText(FilledButton, 'Retry'),
                              )
                              .onPressed !=
                          null),
      );
      final unconfirmedNotices = find
          .textContaining('Do not resend.')
          .evaluate()
          .length;
      final retries = find
          .widgetWithText(FilledButton, 'Retry')
          .evaluate()
          .length;
      final submits = find
          .widgetWithText(FilledButton, 'Submit')
          .evaluate()
          .length;
      final stored = await tester.runAsync(testStore.loadReports);
      expect(
        {
          'unconfirmedNotices': unconfirmedNotices,
          'retries': retries,
          'submits': submits,
          'stored': stored!.map((report) => report.toJson()).toList(),
        },
        {
          'unconfirmedNotices': state == ReportState.submitted ? 0 : 1,
          'retries': 0,
          'submits': 0,
          'stored': [protected.toJson()],
        },
      );
    });
  }

  testWidgets('a failed Draft save warns and retains edits until saving recovers', (
    tester,
  ) async {
    await _openReport(tester);
    await _openPhotos(tester, location);
    await tester.tap(find.text('Skip photo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic saved draft',
    );
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final data = await tester.runAsync(
      SharedPreferencesStorePlatform.instance.getAll,
    );
    final store = _FailingDraftStore(data!);
    SharedPreferencesStorePlatform.instance = store;
    store.delayNextCompletion = true;
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic saved draft before failure',
    );
    await tester.runAsync(() => store.delayedWritten.future);
    final saved = (await tester.runAsync(
      store.getAll,
    ))!['flutter.report_draft_v1'];

    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic unsaved edit',
    );
    await _waitFor(
      tester,
      () => find
          .text(
            'Draft could not be saved. Keep this report open to avoid losing your changes.',
          )
          .evaluate()
          .isNotEmpty,
    );
    store.finishDelayedWrite.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Draft could not be saved. Keep this report open to avoid losing your changes.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-description')))
          .controller!
          .text,
      'Synthetic unsaved edit',
    );
    expect(
      (await tester.runAsync(store.getAll))!['flutter.report_draft_v1'],
      saved,
    );
    expect(tester.takeException(), isNull);
    await _leaveDetailsAndContinueDraft(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-description')))
          .controller!
          .text,
      'Synthetic saved draft before failure',
    );

    store.throwOnWrite = true;
    store.attempted = Completer<void>();
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic edit after storage exception',
    );
    await tester.runAsync(() => store.attempted.future);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Draft could not be saved. Keep this report open to avoid losing your changes.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-description')))
          .controller!
          .text,
      'Synthetic edit after storage exception',
    );
    expect(tester.takeException(), isNull);
    expect(
      (await tester.runAsync(store.getAll))!['flutter.report_draft_v1'],
      saved,
    );
    await _leaveDetailsAndContinueDraft(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-description')))
          .controller!
          .text,
      'Synthetic saved draft before failure',
    );

    store.attempted = Completer<void>();
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic final unsaved edit',
    );
    await tester.runAsync(() => store.attempted.future);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Draft could not be saved. Keep this report open to avoid losing your changes.',
      ),
      findsOneWidget,
    );

    store.failWrites = false;
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic recovered edit',
    );
    await _waitFor(
      tester,
      () => find
          .text(
            'Draft could not be saved. Keep this report open to avoid losing your changes.',
          )
          .evaluate()
          .isEmpty,
    );
    await tester.runAsync(preferences.reload);
    expect(
      jsonDecode(preferences.getString('report_draft_v1')!)['description'],
      'Synthetic recovered edit',
    );
    await tester.pumpWidget(const SizedBox());
    final requests = <http.Request>[];
    final client = PortalSubmissionClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return _syntheticPortalReply(request);
      }),
    );
    await tester.pumpWidget(app.ReportApp(client: client));
    await _waitFor(
      tester,
      () => _homeResumeContinueButton().evaluate().isNotEmpty,
    );
    await tester.tap(_homeResumeContinueButton());
    await _waitFor(
      tester,
      () =>
          find.byKey(const Key('report-description')).evaluate().isNotEmpty &&
          tester
                  .widget<TextField>(
                    find.byKey(const Key('report-description')),
                  )
                  .enabled ==
              true,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report-description')))
          .controller!
          .text,
      'Synthetic recovered edit',
    );

    store.failWrites = true;
    store.throwOnWrite = false;
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Synthetic receipt after local save failure',
    );
    await _waitFor(
      tester,
      () => find
          .text(
            'Draft could not be saved. Keep this report open to avoid losing your changes.',
          )
          .evaluate()
          .isNotEmpty,
    );
    store.finishFailedWrite = Completer<void>();
    store.attempted = Completer<void>();
    await _continue(tester);
    await tester.runAsync(() => store.attempted.future);
    expect(requests, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await _waitFor(
      tester,
      () => find.text('SR-SYNTHETIC-DRAFT').evaluate().isNotEmpty,
    );
    expect(
      find.text(
        'Draft could not be saved. Keep this report open to avoid losing your changes.',
      ),
      findsNothing,
    );
    final reports = await tester.runAsync(testStore.loadReports);
    expect(reports!.single.serviceRequestNumber, 'SR-SYNTHETIC-DRAFT');
    expect(
      reports.single.description,
      'Synthetic receipt after local save failure',
    );
    store.finishFailedWrite!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Draft could not be saved. Keep this report open to avoid losing your changes.',
      ),
      findsNothing,
    );
  });

  testWidgets(
    'an unfinished Draft resumes after restart through Review and controlled submission',
    (tester) async {
      final receipt = Report(
        description: 'Synthetic retained receipt',
        latitude: 34.05,
        longitude: -118.24,
        createdAt: DateTime(2026, 10, 1),
      ).submittedWith('C-04955177');
      await tester.runAsync(() => testStore.saveReport(receipt));
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final cachedPhoto = File('${supportDirectory.path}/synthetic-cache.png')
        ..writeAsBytesSync(bytes);
      camera.result = XFile(cachedPhoto.path);
      final requests = <http.Request>[];
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return _syntheticPortalReply(request);
        }),
      );
      await _openReport(tester, client: client);
      await _openPhotos(tester, location);
      await tester.tap(find.text('Take photo'));
      await _waitFor(tester, () => find.byType(Image).evaluate().isNotEmpty);
      await tester.runAsync(cachedPhoto.delete);
      await _continue(tester);
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic couch beside curb',
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: client));
      await _waitFor(
        tester,
        () => _homeResumeContinueButton().evaluate().isNotEmpty,
      );
      expect(requests, isEmpty);
      await tester.tap(_homeResumeContinueButton());
      await _waitFor(
        tester,
        () =>
            find.byKey(const Key('report-description')).evaluate().isNotEmpty &&
            tester
                    .widget<TextField>(
                      find.byKey(const Key('report-description')),
                    )
                    .enabled ==
                true,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('report-description')))
            .controller!
            .text,
        'Synthetic couch beside curb',
      );
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic corrected couch beside curb',
      );
      await _continue(tester);
      expect(find.text('34.052235, -118.243683'), findsOneWidget);
      expect(find.text('1 item · Curb'), findsOneWidget);
      expect(find.text('Photo attached'), findsOneWidget);
      await tester.tap(find.text('Edit Photo'));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image)).image as FileImage;
      expect(await tester.runAsync(image.file.readAsBytes), bytes);
      await _saveReviewEdit(tester);
      expect(find.text('Photo attached'), findsOneWidget);
      await tester.tap(find.text('Edit Location'));
      await tester.pumpAndSettle();
      location.position = Future.value(
        Position.fromMap({'latitude': 34.06, 'longitude': -118.25}),
      );
      await tester.tap(find.text('Location set ✓'));
      await tester.pumpAndSettle();
      await _saveReviewEdit(tester);
      expect(find.text('34.060000, -118.250000'), findsOneWidget);
      await tester.tap(find.text('Edit Items'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('report-quantity')), '0');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save changes'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('report-quantity')), '4');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alley').last);
      await tester.pumpAndSettle();
      await _saveReviewEdit(tester);
      expect(find.text('4 items · Alley'), findsOneWidget);
      await tester.tap(find.text('Edit Description'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        '   ',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save changes'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic review corrected alley items',
      );
      await _saveReviewEdit(tester);
      expect(
        find.text('Synthetic review corrected alley items'),
        findsOneWidget,
      );
      expect(find.text('Photo attached'), findsOneWidget);
      await tester.tap(find.text('Edit Description'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Edit Location'), findsOneWidget);
      await tester.tap(find.text('Edit Location'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Edit Description'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _waitFor(
        tester,
        () => find.text('SR-SYNTHETIC-DRAFT').evaluate().isNotEmpty,
      );
      final calls = requests.where((request) => request.method == 'POST').map((
        request,
      ) {
        final action =
            (jsonDecode(
                      Uri.splitQueryString(request.body)['message']!,
                    )['actions']
                    as List)
                .single;
        return action['params'] as Map<String, dynamic>;
      }).toList();
      final locate =
          calls.singleWhere(
                (call) => call['method'] == 'validateAddress',
              )['params']
              as Map;
      expect(locate.toString(), contains('34.06'));
      expect(locate.toString(), contains('-118.25'));
      final submitted =
          calls.singleWhere((call) => call['method'] == 'submitCase')['params']
              as Map;
      final questions =
          jsonDecode(
                submitted['sCaseQuestionJSON'] as String,
              )['lstCaseQuestion']
              as List;
      expect(
        questions.singleWhere(
          (question) => question['sFieldtoUpdate'] == 'Description',
        )['sAnswer'],
        'Synthetic review corrected alley items',
      );
      expect(
        questions.singleWhere(
          (question) =>
              question['sFieldtoUpdate'] ==
              'No_of_Loose_Miscellaneous_Debris__c',
        )['sAnswer'],
        '4',
      );
      expect(
        questions.singleWhere(
          (question) =>
              question['sFieldtoUpdate'] ==
              'Location_of_Loose_Miscellaneous_Debris__c',
        )['sAnswer'],
        'Alley',
      );
      expect(submitted['sFileLinks'], contains(base64Encode(bytes)));
      expect(
        jsonDecode(submitted['sObjContact'] as String)['isAnonymously'],
        isTrue,
      );
      final reports = await tester.runAsync(testStore.loadReports);
      expect(reports!.last.toJson(), receipt.toJson());
      expect(reports.first.serviceRequestNumber, 'SR-SYNTHETIC-DRAFT');
      final requestCount = requests.length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: client));
      await tester.pumpAndSettle();
      expect(_homeResumeContinueButton(), findsNothing);
      expect(requests.length, requestCount);
    },
  );

  testWidgets('the native entry point opens the illegal dumping home', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reports-brand-logo')), findsOneWidget);
    expect(find.text('Report illegal dumping.'), findsOneWidget);
    expect(find.text('Start a report'), findsOneWidget);
    expect(find.text('View saved reports'), findsOneWidget);
  });

  testWidgets(
    'My reports opens a saved report and returns to the home screen',
    (tester) async {
      await tester.runAsync(
        () => testStore.saveReport(
          Report(
            description: 'Mattress beside the curb',
            latitude: 34.052235,
            longitude: -118.243683,
            createdAt: DateTime(2026, 10, 22),
          ),
        ),
      );
      await tester.pumpWidget(app.ReportApp(client: _NoSubmissionClient()));
      await tester.tap(find.text('View saved reports'));
      await _waitFor(
        tester,
        () => find.text('Mattress beside the curb').evaluate().isNotEmpty,
      );

      expect(find.text('Not sent'), findsOneWidget);
      await tester.tap(find.text('Mattress beside the curb'));
      await tester.pumpAndSettle();
      expect(find.text('Report details'), findsOneWidget);
      expect(find.text('Mattress beside the curb'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Start a report'), findsOneWidget);
    },
  );

  testWidgets('a camera photo is previewed and cancelling keeps that photo', (
    tester,
  ) async {
    final photo = File('${supportDirectory.path}/dump.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    camera.result = XFile(photo.path);
    await _openReport(tester);
    await _openPhotos(tester, location);
    await tester.runAsync(
      () => precacheImage(
        FileImage(photo),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.tap(find.text('Take photo'));
    await _waitFor(tester, () => find.byType(Image).evaluate().isNotEmpty);
    final preview = tester.widget<Image>(find.byType(Image)).image;
    await tester.runAsync(
      () => precacheImage(preview, tester.element(find.byType(Scaffold))),
    );

    expect(find.image(preview), findsOneWidget);
    camera.result = null;
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(find.image(preview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed photo copy explains the failure and keeps the preview', (
    tester,
  ) async {
    final photo = File('${supportDirectory.path}/dump.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    camera.result = XFile(photo.path);
    await _openReport(tester);
    await _openPhotos(tester, location);
    await tester.tap(find.text('Take photo'));
    await _waitFor(tester, () => find.byType(Image).evaluate().isNotEmpty);
    final preview = tester.widget<Image>(find.byType(Image)).image;
    await tester.runAsync(
      () => precacheImage(preview, tester.element(find.byType(Scaffold))),
    );
    camera.result = XFile('${supportDirectory.path}/missing.png');
    await tester.tap(find.text('Take photo'));
    await _waitFor(
      tester,
      () => find
          .text('Photo could not be saved. Please try again.')
          .evaluate()
          .isNotEmpty,
    );

    expect(find.image(preview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved camera photo survives removal of its cache file', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final cachedPhoto = File('${supportDirectory.path}/camera-cache.png')
      ..writeAsBytesSync(bytes);
    camera.result = XFile(cachedPhoto.path);
    location.permission = LocationPermission.whileInUse;
    await _openReport(tester, client: _OfflineClient());
    await _openPhotos(tester, location);
    await tester.tap(find.text('Take photo'));
    await _waitFor(tester, () => find.byType(Image).evaluate().isNotEmpty);
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(find.byType(Image)).image,
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.runAsync(cachedPhoto.delete);
    await _continue(tester);
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Mattress at the curb',
    );
    await _continue(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await _waitFor(
      tester,
      () => find.text('Not sent: Offline fixture').evaluate().isNotEmpty,
    );

    final reports = await tester.runAsync(testStore.loadReports);
    final savedPhoto = File(reports!.single.photoPath!);
    expect(await tester.runAsync(savedPhoto.exists), isTrue);
    expect(await tester.runAsync(savedPhoto.readAsBytes), bytes);
  });

  testWidgets('disabled location explains how to enable it and try again', (
    tester,
  ) async {
    location.enabled = false;
    await _openReport(tester);
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Location services are off. Turn them on in Settings, then tap Use my location again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Location set ✓'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'the report retains required answers when returning from review',
    (tester) async {
      await _openReport(tester);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await _openPhotos(tester, location);
      await tester.tap(find.text('Skip photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Mattress by the curb',
      );
      await _continue(tester);

      expect(find.text('Looking good? Take a look.'), findsOneWidget);
      expect(find.text('1 item · Curb'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('report-description')))
            .controller!
            .text,
        'Mattress by the curb',
      );
      await _continue(tester);
      expect(find.text('Mattress by the curb'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Continue stays above the keyboard in Items and Details', (
    tester,
  ) async {
    await _openReport(tester);
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetViewInsets);
    location.permission = LocationPermission.whileInUse;
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    await _continue(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curb').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('report-quantity')), '1');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.widgetWithText(FilledButton, 'Continue')).bottom,
      lessThanOrEqualTo(544),
    );
    await _continue(tester);
    await tester.tap(find.text('Skip photo'));
    await tester.pumpAndSettle();
    expect(find.text('Add a little detail.'), findsOneWidget);
    expect(
      tester.getRect(find.widgetWithText(FilledButton, 'Continue')).bottom,
      lessThanOrEqualTo(544),
    );
  });

  testWidgets(
    'system back preserves report answers before leaving at Location',
    (tester) async {
      await _openReport(tester);
      await _openPhotos(tester, location);
      await tester.tap(find.text('Skip photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Couch near the curb',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Have a photo?'), findsOneWidget);
      await tester.tap(find.text('Skip photo'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('report-description')))
            .controller!
            .text,
        'Couch near the curb',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('report-quantity')))
            .controller!
            .text,
        '1',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Where did you spot it?'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Start a report'), findsOneWidget);
    },
  );

  testWidgets('review remains readable at 320px with doubled text', (
    tester,
  ) async {
    await _openReport(tester);
    await _openPhotos(tester, location);
    await tester.tap(find.text('Skip photo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Couch near the curb',
    );
    await _continue(tester);
    tester.view.physicalSize = const Size(320, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Edit Description'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Couch near the curb'), findsOneWidget);
    expect(
      tester.getRect(find.text('Edit Description')).right,
      lessThanOrEqualTo(300),
    );
  });

  testWidgets('a location result after Back leaves the home screen usable', (
    tester,
  ) async {
    final result = Completer<Position>();
    location.permission = LocationPermission.whileInUse;
    location.position = result.future;
    await _openReport(tester);
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    result.complete(
      Position.fromMap({
        'latitude': 34.052235,
        'longitude': -118.243683,
        'timestamp': 1787000000000,
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start a report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'denied location permission explains how to recover without coordinates',
    (tester) async {
      await _openReport(tester);

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Location permission is denied.'),
        findsOneWidget,
      );
      expect(find.text('Location set ✓'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
    },
  );
}

Future<void> _openReport(
  WidgetTester tester, {
  SubmissionClient? client,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 2000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    app.ReportApp(client: client ?? _NoSubmissionClient()),
  );
  await tester.tap(find.text('Start a report'));
  await _waitFor(
    tester,
    () =>
        find.text('Where did you spot it?').evaluate().isNotEmpty &&
        tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Use my location'),
                )
                .onPressed !=
            null,
  );
}

Future<void> _openPhotos(WidgetTester tester, _Location location) async {
  location.permission = LocationPermission.whileInUse;
  await tester.tap(find.text('Use my location'));
  await tester.pumpAndSettle();
  await _continue(tester);
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Curb').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('report-quantity')), '1');
  await _continue(tester);
}

Future<void> _leaveDetailsAndContinueDraft(WidgetTester tester) async {
  for (var step = 0; step < 4; step++) {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
  await _waitFor(
    tester,
    () => _homeResumeContinueButton().evaluate().isNotEmpty,
  );
  await tester.tap(_homeResumeContinueButton());
  await _waitFor(
    tester,
    () =>
        find.byKey(const Key('report-description')).evaluate().isNotEmpty &&
        tester
                .widget<TextField>(find.byKey(const Key('report-description')))
                .enabled ==
            true,
  );
}

Future<void> _saveReviewEdit(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
  await tester.pumpAndSettle();
  expect(find.text('Edit Location'), findsOneWidget);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() ready, {
  Duration step = Duration.zero,
}) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump(step);
    }
  });
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

class _Camera extends ImagePickerPlatform {
  XFile? result;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => result;
}

class _Location extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  Future<Position>? position;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    final pending = position;
    if (pending != null) return pending;
    return Position.fromMap({
      'latitude': 34.052235,
      'longitude': -118.243683,
      'timestamp': 1787000000000,
    });
  }
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _NoSubmissionClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) {
    throw StateError('Platform checks must not submit a report');
  }
}

class _OfflineClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) async =>
      SubmissionFailed(SubmissionFailureKind.network, 'Offline fixture');
}

class _FailingDraftStore extends InMemorySharedPreferencesStore {
  _FailingDraftStore(super.data) : super.withData();

  bool delayNextCompletion = false;
  final delayedWritten = Completer<void>();
  final finishDelayedWrite = Completer<void>();
  bool failWrites = true;
  bool throwOnWrite = false;
  Completer<void>? finishFailedWrite;
  Completer<void> attempted = Completer<void>();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.report_draft_v1' && delayNextCompletion) {
      delayNextCompletion = false;
      final result = await super.setValue(valueType, key, value);
      delayedWritten.complete();
      await finishDelayedWrite.future;
      return result;
    }
    if (key == 'flutter.report_draft_v1' && failWrites) {
      if (!attempted.isCompleted) attempted.complete();
      await finishFailedWrite?.future;
      if (throwOnWrite) {
        throw StateError('Synthetic preference write exception');
      }
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

http.Response _syntheticPortalReply(http.Request request) {
  if (request.method == 'GET') {
    return http.Response(
      '<script>{"fwuid":"synthetic-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"synthetic-app"}}</script>',
      200,
    );
  }
  final action =
      (jsonDecode(Uri.splitQueryString(request.body)['message']!)['actions']
              as List)
          .single;
  final method = action['params']['method'];
  final parameters = action['params']['params'] as Map;
  final response = switch (method) {
    'fetchInitialDetails' => {
      'popularCaseList': [
        {
          'uxType': 'Illegal Dumping Item Pickup',
          'caseConfigId': 'synthetic-type',
        },
      ],
    },
    'fetchCaseTypeDetails' => {
      'objCaseConfigWrapper': {
        'sCaseType': 'Illegal Dumping Item Pickup',
        'sCasePriority': 'Normal',
        'sCaseDefaultStatus': 'New',
        'lstCaseQuestion': [
          for (final field in [
            'Description',
            'Location_of_Loose_Miscellaneous_Debris__c',
            'No_of_Loose_Miscellaneous_Debris__c',
          ])
            {'sFieldtoUpdate': field},
        ],
      },
      'contactWrapperResponse': {'bIsLogin': false},
    },
    'validateAddress' => jsonEncode({
      'address': {
        'ShortLabel': 'SYNTHETIC CURB',
        'City': 'LOS ANGELES',
        'X': parameters['longitude'],
        'Y': parameters['latitude'],
      },
      'location': {'x': parameters['longitude'], 'y': parameters['latitude']},
    }),
    'submitCase' => {'sCaseNumber': 'SR-SYNTHETIC-DRAFT'},
    _ => throw StateError('Unexpected synthetic Portal method $method'),
  };
  return http.Response(
    jsonEncode({
      'actions': [
        {
          'state': 'SUCCESS',
          'returnValue': {
            'returnValue': jsonEncode({
              'isSuccess': true,
              'message': 'Synthetic response',
              'response': response,
            }),
          },
        },
      ],
    }),
    200,
  );
}

class _RemovalStore extends InMemorySharedPreferencesStore {
  _RemovalStore(super.data) : super.withData();
  bool failRemoval = true;
  bool failRows = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.reports_v2' && failRows) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (key == 'flutter.report_draft_v1' && failRemoval) return false;
    return super.remove(key);
  }
}
