import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart' as app;
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

Finder _homeResumeContinueButton() => find.descendant(
  of: find.byKey(const Key('home-resume-card')),
  matching: find.text('Continue'),
);

void main() {
  test(
    'unsupported photo counts and sizes reject before any City call',
    () async {
      final directory = Directory(
        '.dart_tool',
      ).absolute.createTempSync('synthetic-photo-limits-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final oversized = File('${directory.path}/oversized.png')
        ..writeAsBytesSync(List.filled(10000001, 0));
      final requests = <http.Request>[];
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return _syntheticReply(request);
        }),
      );
      final outcomes = <Map<String, Object?>>[];
      for (final paths in [
        List.filled(4, oversized.path),
        [oversized.path],
      ]) {
        final result = await client.send(
          Report(
            createdAt: DateTime.utc(2026, 10, 22),
            description: 'Synthetic unsupported attachment',
            latitude: 34.05,
            longitude: -118.24,
            debrisLocation: 'Curb',
            quantity: 2,
            photoPaths: paths,
          ),
        );
        outcomes.add({
          'failed': result is SubmissionFailed,
          'kind': result is SubmissionFailed ? result.kind : null,
        });
      }
      expect(
        {'results': outcomes, 'requests': requests},
        {
          'results': [
            {'failed': true, 'kind': SubmissionFailureKind.rejected},
            {'failed': true, 'kind': SubmissionFailureKind.rejected},
          ],
          'requests': <http.Request>[],
        },
      );
    },
  );

  testWidgets(
    'three retained photos survive removal, restart and real client payload',
    (tester) async {
      final support = Directory(
        '.dart_tool',
      ).absolute.createTempSync('synthetic-multiple-');
      final originalPaths = PathProviderPlatform.instance;
      final originalPicker = ImagePickerPlatform.instance;
      final picker = _PhotoPicker();
      final outcomes = <String, Object?>{};
      PathProviderPlatform.instance = _PhotoPath(support.path);
      ImagePickerPlatform.instance = picker;
      addTearDown(() {
        PathProviderPlatform.instance = originalPaths;
        ImagePickerPlatform.instance = originalPicker;
        support.deleteSync(recursive: true);
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final sources = [
        for (var index = 0; index < 4; index++)
          File('${support.path}/synthetic-$index.png')
            ..writeAsBytesSync([...bytes, index]),
      ];
      final draft = ReportDraft(
        createdAt: DateTime.utc(2026, 10, 22),
        description: 'Synthetic couch and bags with three photos',
        latitude: 34.052235,
        longitude: -118.243683,
        photoPaths: [sources[0].path, sources[1].path],
        debrisLocation: 'Curb',
        quantity: '2',
        step: 2,
      );
      SharedPreferences.setMockInitialValues({
        'report_draft_v1': jsonEncode(draft.toJson()),
      });
      final requests = <http.Request>[];
      var rejected = false;
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST' &&
              _params(request)['method'] == 'submitCase' &&
              !rejected) {
            rejected = true;
            return http.Response(
              jsonEncode({
                'actions': [
                  {
                    'state': 'SUCCESS',
                    'returnValue': {
                      'returnValue': jsonEncode({
                        'isSuccess': false,
                        'message': 'Synthetic known rejection',
                        'response': null,
                      }),
                    },
                  },
                ],
              }),
              200,
            );
          }
          return _syntheticReply(request);
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
        () => find.text('Have a photo?').evaluate().isNotEmpty,
      );
      outcomes['restoredPhotoCount'] = find.byType(Image).evaluate().length;
      await _waitFor(
        tester,
        () =>
            tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Choose from library'),
                )
                .onPressed !=
            null,
      );
      picker.pending = Completer<XFile?>()..complete(XFile(sources[2].path));
      await tester.tap(find.text('Choose from library'));
      await _waitFor(
        tester,
        () =>
            find
                .byWidgetPredicate(
                  (widget) => widget is Image && widget.image is FileImage,
                )
                .evaluate()
                .length ==
            3,
      );
      outcomes['libraryDisabledAtLimit'] =
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Choose from library'),
              )
              .onPressed ==
          null;
      outcomes['cameraDisabledAtLimit'] =
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Take photo'),
              )
              .onPressed ==
          null;
      await tester.tap(find.byKey(const ValueKey('remove-photo-1')));
      await tester.pumpAndSettle();
      outcomes['photoCountAfterRemoval'] = find.byType(Image).evaluate().length;
      outcomes['removedFileRetained'] = sources[1].existsSync();
      picker.pending = Completer<XFile?>()..complete(XFile(sources[3].path));
      await tester.tap(find.text('Choose from library'));
      await _waitFor(
        tester,
        () =>
            find
                .byWidgetPredicate(
                  (widget) => widget is Image && widget.image is FileImage,
                )
                .evaluate()
                .length ==
            3,
      );
      final paths = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as FileImage).file.path)
          .toList();
      final retained = await tester.runAsync(testStore.loadDraft);
      outcomes['retainedDraftPaths'] = retained?.photoPaths;
      outcomes['firstPhotoPath'] = paths.first;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app.ReportApp(client: client));
      await _waitFor(
        tester,
        () => _homeResumeContinueButton().evaluate().isNotEmpty,
      );
      await tester.tap(_homeResumeContinueButton());
      await _waitFor(
        tester,
        () =>
            find
                .byWidgetPredicate(
                  (widget) => widget is Image && widget.image is FileImage,
                )
                .evaluate()
                .length ==
            3,
      );
      outcomes['restartedPhotoPaths'] = tester
          .widgetList<Image>(
            find.byWidgetPredicate(
              (widget) => widget is Image && widget.image is FileImage,
            ),
          )
          .map((image) => (image.image as FileImage).file.path)
          .toList();
      await _continue(tester);
      await _continue(tester);
      outcomes['reviewPhotoLabelCount'] = find
          .text('3 photos attached')
          .evaluate()
          .length;
      outcomes['reviewDescriptionCount'] = find
          .text(draft.description)
          .evaluate()
          .length;
      await tester.tap(find.text('Edit Photo'));
      await tester.pumpAndSettle();
      outcomes['reviewEditPhotoCount'] = find
          .byWidgetPredicate(
            (widget) => widget is Image && widget.image is FileImage,
          )
          .evaluate()
          .length;
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      outcomes['savedReviewPhotoLabelCount'] = find
          .text('3 photos attached')
          .evaluate()
          .length;
      outcomes['unexpectedDetailsFields'] = find
          .byKey(const Key('report-description'))
          .evaluate()
          .length;
      await _waitFor(
        tester,
        () =>
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Submit'),
                )
                .onPressed !=
            null,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _waitFor(
        tester,
        () => find
            .text('Your report is saved as not sent.')
            .evaluate()
            .isNotEmpty,
      );
      final failed = await tester.runAsync(testStore.loadReports);
      outcomes['knownFailurePhotoPaths'] = failed
          ?.map((report) => report.photoPaths)
          .toList();
      outcomes['knownFailureStates'] = failed
          ?.map((report) => report.state)
          .toList();
      await tester.tap(find.text('Edit Description'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        '${draft.description} corrected',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      outcomes['correctedReviewPhotoLabelCount'] = find
          .text('3 photos attached')
          .evaluate()
          .length;
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await _waitFor(
        tester,
        () => find.text('SR-SYNTHETIC-LIBRARY').evaluate().isNotEmpty,
      );
      final submissions = requests
          .where((r) => r.method == 'POST')
          .map(_params)
          .where((call) => call['method'] == 'submitCase')
          .toList();
      outcomes['submissionCount'] = submissions.length;
      final sentPhotoBytes = <List<Object?>>[];
      for (final submission in submissions) {
        final params = submission['params'] as Map<String, dynamic>;
        final attachments = jsonDecode(params['sFileLinks'] as String) as List;
        sentPhotoBytes.add(
          attachments.map((photo) => photo['fileData'] as Object?).toList(),
        );
      }
      outcomes['sentPhotoBytes'] = sentPhotoBytes;
      final reports = await tester.runAsync(testStore.loadReports);
      outcomes['savedReportPaths'] = reports
          ?.map((report) => report.photoPaths)
          .toList();
      outcomes['savedServiceRequests'] = reports
          ?.map((report) => report.serviceRequestNumber)
          .toList();
      outcomes['savedDescriptions'] = reports
          ?.map((report) => report.description)
          .toList();
      final expectedPhotoBytes = [
        for (final index in [0, 2, 3]) base64Encode([...bytes, index]),
      ];
      expect(outcomes, {
        'restoredPhotoCount': 2,
        'libraryDisabledAtLimit': true,
        'cameraDisabledAtLimit': true,
        'photoCountAfterRemoval': 2,
        'removedFileRetained': true,
        'retainedDraftPaths': paths,
        'firstPhotoPath': sources[0].path,
        'restartedPhotoPaths': paths,
        'reviewPhotoLabelCount': 1,
        'reviewDescriptionCount': 1,
        'reviewEditPhotoCount': 3,
        'savedReviewPhotoLabelCount': 1,
        'unexpectedDetailsFields': 0,
        'knownFailurePhotoPaths': [paths],
        'knownFailureStates': [ReportState.notSent],
        'correctedReviewPhotoLabelCount': 1,
        'submissionCount': 2,
        'sentPhotoBytes': [expectedPhotoBytes, expectedPhotoBytes],
        'savedReportPaths': [paths],
        'savedServiceRequests': ['SR-SYNTHETIC-LIBRARY'],
        'savedDescriptions': ['${draft.description} corrected'],
      });
    },
  );

  test('ordered photos survive draft and receipt serialization', () {
    final legacyDraft = ReportDraft(
      createdAt: DateTime.utc(2026, 10, 22),
      photoPath: 'synthetic-first.png',
    ).toJson();
    final legacyReceipt = Report(
      createdAt: DateTime.utc(2026, 10, 1),
      description: 'Synthetic retained multi-photo receipt',
      latitude: 34.05,
      longitude: -118.24,
      photoPath: 'synthetic-first.png',
    ).submittedWith('SR-SYNTHETIC-PHOTOS').toJson();
    final photos = [
      'synthetic-first.png',
      'synthetic-second.png',
      'synthetic-third.png',
    ];
    final draft = {...legacyDraft, 'photoPaths': photos};
    final receipt = {...legacyReceipt, 'photoPaths': photos};
    expect(ReportDraft.fromJson(draft).toJson(), draft);
    expect(
      Report.fromJson(receipt).submittedWith('SR-SYNTHETIC-PHOTOS').toJson(),
      receipt,
    );
    expect(ReportDraft.fromJson(legacyDraft).toJson(), legacyDraft);
    expect(Report.fromJson(legacyReceipt).toJson(), legacyReceipt);
  });

  testWidgets('removing a photo survives restart and sends no attachment', (
    tester,
  ) async {
    final support = Directory(
      '.dart_tool',
    ).absolute.createTempSync('synthetic-removal-');
    final originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _PhotoPath(support.path);
    addTearDown(() => PathProviderPlatform.instance = originalPaths);
    addTearDown(() => support.deleteSync(recursive: true));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photo = File('${support.path}/retained.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    final draft = ReportDraft(
      createdAt: DateTime(2026, 10, 22),
      description: 'Synthetic photo removal couch',
      latitude: 34.052235,
      longitude: -118.243683,
      photoPath: photo.path,
      debrisLocation: 'Curb',
      quantity: '2',
      step: 4,
    );
    final receipt = Report(
      createdAt: DateTime(2026, 10, 1),
      description: 'Synthetic receipt sharing retained photo',
      latitude: 34.05,
      longitude: -118.24,
      photoPath: photo.path,
    ).submittedWith('SR-SYNTHETIC-KEEP-PHOTO');
    SharedPreferences.setMockInitialValues({
      'report_draft_v1': jsonEncode(draft.toJson()),
      'reports_v2': [jsonEncode(receipt.toJson())],
    });
    final requests = <http.Request>[];
    final client = PortalSubmissionClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return _syntheticReply(request);
      }),
    );
    await tester.pumpWidget(app.ReportApp(client: client));
    await _waitFor(
      tester,
      () => _homeResumeContinueButton().evaluate().isNotEmpty,
    );
    await tester.tap(_homeResumeContinueButton());
    await _waitFor(tester, () => find.text('Edit Photo').evaluate().isNotEmpty);
    await _waitFor(
      tester,
      () =>
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Edit Photo'))
              .onPressed !=
          null,
    );
    await tester.tap(find.text('Edit Photo'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    final retained = await tester.runAsync(testStore.loadDraft);
    expect(retained!.toJson(), {
      ...draft.toJson(),
      'photoPath': null,
      'step': 2,
    });
    expect(photo.existsSync(), isTrue);
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('No photo added'), findsOneWidget);
    expect(find.text('2 items · Curb'), findsOneWidget);
    expect(find.text(draft.description), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app.ReportApp(client: client));
    await _waitFor(
      tester,
      () => _homeResumeContinueButton().evaluate().isNotEmpty,
    );
    await tester.tap(_homeResumeContinueButton());
    await _waitFor(
      tester,
      () => find.text('No photo added').evaluate().isNotEmpty,
    );
    expect(requests, isEmpty);
    await _waitFor(
      tester,
      () =>
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'))
              .onPressed !=
          null,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await _waitFor(
      tester,
      () => find.text('SR-SYNTHETIC-LIBRARY').evaluate().isNotEmpty,
    );
    final submit = requests
        .where((request) => request.method == 'POST')
        .map(_params)
        .singleWhere((call) => call['method'] == 'submitCase');
    final params = submit['params'] as Map<String, dynamic>;
    expect(jsonDecode(params['sFileLinks'] as String), isEmpty);
    final reports = await tester.runAsync(testStore.loadReports);
    expect(reports!.first.photoPath, isNull);
    expect(reports.last.toJson(), receipt.toJson());
    expect(photo.existsSync(), isTrue);
  });

  testWidgets(
    'a library photo remains usable after cancellation and permission failure',
    (tester) async {
      final support = Directory(
        '.dart_tool',
      ).absolute.createTempSync('synthetic-photo-');
      final originalPaths = PathProviderPlatform.instance;
      final originalPicker = ImagePickerPlatform.instance;
      final picker = _PhotoPicker();
      PathProviderPlatform.instance = _PhotoPath(support.path);
      ImagePickerPlatform.instance = picker;
      addTearDown(() async {
        PathProviderPlatform.instance = originalPaths;
        ImagePickerPlatform.instance = originalPicker;
        await support.delete(recursive: true);
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = ReportDraft(
        createdAt: DateTime(2026, 10, 22),
        description: 'Synthetic library couch beside curb',
        latitude: 34.052235,
        longitude: -118.243683,
        debrisLocation: 'Curb',
        quantity: '2',
        step: 2,
      );
      final receipt = Report(
        createdAt: DateTime(2026, 10, 1),
        description: 'Synthetic retained receipt',
        latitude: 34.05,
        longitude: -118.24,
      ).submittedWith('SR-SYNTHETIC-OLD-PHOTO');
      SharedPreferences.setMockInitialValues({
        'report_draft_v1': jsonEncode(draft.toJson()),
        'reports_v2': [jsonEncode(receipt.toJson())],
      });
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final cache = File('${support.path}/synthetic-library.png')
        ..writeAsBytesSync(bytes);
      final requests = <http.Request>[];
      final client = PortalSubmissionClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return _syntheticReply(request);
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
        () => find.text('Have a photo?').evaluate().isNotEmpty,
      );
      expect(find.text('Choose from library'), findsOneWidget);
      await _waitFor(
        tester,
        () =>
            tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Choose from library'),
                )
                .onPressed !=
            null,
      );
      picker.pending = Completer<XFile?>();
      await tester.tap(find.text('Choose from library'));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Take photo'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Choose from library'),
            )
            .onPressed,
        isNull,
      );
      picker.pending!.complete(XFile(cache.path));
      await _waitFor(tester, () => find.byType(Image).evaluate().isNotEmpty);
      final image = tester.widget<Image>(find.byType(Image)).image as FileImage;
      expect(image.file.path == cache.path, isFalse);
      expect(await tester.runAsync(image.file.readAsBytes), bytes);
      await tester.runAsync(cache.delete);
      final retained = await tester.runAsync(testStore.loadDraft);
      expect(retained!.toJson(), {
        ...draft.toJson(),
        'photoPath': image.file.path,
      });
      picker.pending = null;
      await tester.tap(find.text('Choose from library'));
      await tester.pumpAndSettle();
      expect(find.image(image), findsOneWidget);
      picker.failure = PlatformException(code: 'photo_access_denied');
      await tester.tap(find.text('Choose from library'));
      await tester.pumpAndSettle();
      expect(find.image(image), findsOneWidget);
      expect(
        find.text('Photo could not be saved. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      picker.failure = null;
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(picker.sources, [
        ImageSource.gallery,
        ImageSource.gallery,
        ImageSource.gallery,
        ImageSource.camera,
      ]);
      expect(find.image(image), findsOneWidget);
      expect(requests, isEmpty);
      await _continue(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('report-description')))
            .controller!
            .text,
        draft.description,
      );
      await _continue(tester);
      expect(find.text('2 items · Curb'), findsOneWidget);
      expect(find.text('Photo attached'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await _waitFor(
        tester,
        () => find.text('SR-SYNTHETIC-LIBRARY').evaluate().isNotEmpty,
      );
      final calls = requests
          .where((request) => request.method == 'POST')
          .map(_params)
          .toList();
      final submission =
          calls.singleWhere((call) => call['method'] == 'submitCase')['params']
              as Map<String, dynamic>;
      final attachments =
          jsonDecode(submission['sFileLinks'] as String) as List;
      expect(attachments, [
        {
          'fileData': base64Encode(bytes),
          'fileName': 'photo.png',
          'showImage': true,
          'showPdf': false,
          'fileType': 'png',
          'position': null,
        },
      ]);
      final reports = await tester.runAsync(testStore.loadReports);
      expect(reports!.last.toJson(), receipt.toJson());
    },
  );
}

Future<void> _continue(WidgetTester tester) async {
  await _waitFor(
    tester,
    () =>
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed !=
        null,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  expect(
    ready(),
    isTrue,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .join(' | '),
  );
  await tester.pumpAndSettle();
}

class _PhotoPicker extends ImagePickerPlatform {
  Completer<XFile?>? pending;
  Object? failure;
  final sources = <ImageSource>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    final error = failure;
    if (error != null) throw error;
    return pending?.future;
  }
}

class _PhotoPath extends PathProviderPlatform {
  _PhotoPath(this.path);
  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Map<String, dynamic> _params(http.Request request) =>
    ((jsonDecode(Uri.splitQueryString(request.body)['message']!)['actions']
                as List)
            .single['params']
        as Map<String, dynamic>);

http.Response _syntheticReply(http.Request request) {
  if (request.method == 'GET') {
    return http.Response(
      '<script>{"fwuid":"synthetic-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"synthetic-app"}}</script>',
      200,
    );
  }
  final response = switch (_params(request)['method']) {
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
        'X': -118.243683,
        'Y': 34.052235,
      },
      'location': {'x': -118.243683, 'y': 34.052235},
    }),
    'submitCase' => {'sCaseNumber': 'SR-SYNTHETIC-LIBRARY'},
    final method => throw StateError('Unexpected synthetic method $method'),
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
