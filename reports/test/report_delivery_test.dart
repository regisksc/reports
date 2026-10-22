import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/home/presentation/report_delivery_painter.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/home/presentation/report_delivery_scene.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

Finder _homeResumeContinueButton() => find.descendant(
  of: find.byKey(const Key('home-resume-card')),
  matching: find.text('Continue'),
);

void main() {
  for (final mode in ['normal', 'system', 'session']) {
    testWidgets(
      'accepted report settles into the same Home hero with $mode motion',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final originalPaths = PathProviderPlatform.instance;
        final support = Directory('.dart_tool').createTempSync('delivery-');
        PathProviderPlatform.instance = _SupportPath(support.absolute.path);
        addTearDown(() async {
          PathProviderPlatform.instance = originalPaths;
          await support.delete(recursive: true);
        });
        final outcomes = <Map<String, Object?>>[];
        final expected = <Map<String, Object?>>[];
        final storyboards = Directory(
          '${Directory.current.parent.path}/.scratch/illegal-dump-reporter/evidence/ticket25/storyboard',
        )..createSync(recursive: true);
        final reduced = mode != 'normal';
        await tester.pumpWidget(const SizedBox());
        SharedPreferences.setMockInitialValues({});
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(reduceMotion: mode == 'system');
        await testStore.saveDraft(
          ReportDraft(
            createdAt: DateTime(2026, 10, 22),
            latitude: 34.052235,
            longitude: -118.243683,
            debrisLocation: 'Curb',
            quantity: '2',
            description: 'Synthetic authored delivery, no City write',
            step: 4,
          ),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('delivery-screen'),
            child: ReportApp(
              client: PortalSubmissionClient(
                httpClient: MockClient(
                  (request) async => _syntheticPortalReply(request),
                ),
              ),
            ),
          ),
        );
        await _waitFor(
          tester,
          () => _homeResumeContinueButton().evaluate().isNotEmpty,
        );
        if (mode == 'session') {
          await tester.tap(find.byTooltip('Motion settings'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(
              CheckedPopupMenuItem<bool>,
              'Reduce motion for this session',
            ),
          );
        }
        await tester.pumpAndSettle();
        final heroBefore = tester.getRect(find.byKey(const Key('home-hero')));
        await tester.ensureVisible(_homeResumeContinueButton());
        await tester.tap(_homeResumeContinueButton());
        await _waitFor(
          tester,
          () =>
              find
                  .widgetWithText(FilledButton, 'Submit')
                  .evaluate()
                  .isNotEmpty &&
              tester
                      .widget<FilledButton>(
                        find.widgetWithText(FilledButton, 'Submit'),
                      )
                      .onPressed !=
                  null,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit'));
        await _waitFor(
          tester,
          () => find.text('SYNTHETIC-SR-25').evaluate().isNotEmpty,
        );
        final scene = find.byKey(const Key('report-delivery-scene'));
        final initialSceneCount = scene.evaluate().length;
        await tester.pump();
        final heroOnAcceptance = tester.getRect(
          find.byKey(const Key('home-hero')),
        );
        expect(heroOnAcceptance.size, heroBefore.size);
        if (!reduced) {
          expect(
            (tester.widget<CustomPaint>(scene).painter!
                    as ReportDeliveryPainter)
                .heroBounds,
            heroOnAcceptance,
          );
        }
        final retainedBeforeScene = (await tester.runAsync(
          testStore.loadReports,
        ))!.single;
        var frame = 0;
        for (final milliseconds
            in reduced
                ? <int>[]
                : [
                    600,
                    800,
                    400,
                    200,
                    350,
                    200,
                    200,
                    250,
                    550,
                    230,
                    220,
                    400,
                    1400,
                  ]) {
          await tester.pump(Duration(milliseconds: milliseconds));
          if (scene.evaluate().isNotEmpty) {
            expect(
              (tester.widget<CustomPaint>(scene).painter!
                      as ReportDeliveryPainter)
                  .heroBounds,
              heroOnAcceptance,
            );
          }
          await _saveFrame(
            tester,
            File('${storyboards.path}/normal-${frame++}.png'),
          );
        }
        await tester.pumpAndSettle();
        await _saveFrame(tester, File('${storyboards.path}/$mode-home.png'));
        final outcome = <String, Object?>{
          'reduced': reduced,
          'sceneOnAcceptance': initialSceneCount,
          'retainedStateBeforeScene': retainedBeforeScene.state,
          'retainedNumberBeforeScene': retainedBeforeScene.serviceRequestNumber,
          'heroAfter': tester.getRect(find.byKey(const Key('home-hero'))),
          'sceneAfterCompletion': scene.evaluate().length,
          'receiptAfterCompletion': find
              .text('SYNTHETIC-SR-25')
              .evaluate()
              .length,
        };
        await tester.ensureVisible(find.text('Start a report'));
        await tester.tap(find.text('Start a report'));
        await _waitFor(
          tester,
          () => find.text('Where did you spot it?').evaluate().isNotEmpty,
        );
        outcome['startStillUsable'] = find
            .text('Where did you spot it?')
            .evaluate()
            .length;
        outcomes.add(outcome);
        expected.add({
          'reduced': reduced,
          'sceneOnAcceptance': reduced ? 0 : 1,
          'retainedStateBeforeScene': ReportState.submitted,
          'retainedNumberBeforeScene': 'SYNTHETIC-SR-25',
          'heroAfter': heroOnAcceptance,
          'sceneAfterCompletion': 0,
          'receiptAfterCompletion': 1,
          'startStillUsable': 1,
        });
        expect(outcomes, expected);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  test('town hall shrinks uniformly into the final centered Home hero', () {
    const bounds = Rect.fromLTWH(20, 96, 350, 415);
    const screen = Size(390, 844);
    var previousScale = double.infinity;
    for (final seconds in [4.4, 4.7, 5.1, 5.5, 5.8]) {
      final canvas = _GeometryCanvas();
      ReportDeliveryPainter(
        seconds: seconds,
        heroBounds: bounds,
      ).paint(canvas, screen);
      final settle = Curves.easeInOutCubic.transform(
        ((seconds - 4.4) / 1.4).clamp(0, 1),
      );
      final frame = Rect.lerp(Offset.zero & screen, bounds, settle)!;
      expect(canvas.translations.first, [
        closeTo(screen.width / 2, 0.001),
        closeTo(frame.center.dy, 0.001),
      ]);
      expect(
        canvas.scales.first.single,
        closeTo(math.min(frame.width / 1120, frame.height / 820), 0.000001),
      );
      expect(canvas.scales.first.single, lessThanOrEqualTo(previousScale));
      previousScale = canvas.scales.first.single;
    }
  });

  testWidgets('a completed accepted scene settles once', (tester) async {
    var completions = 0;
    await tester.pumpWidget(_scene(onComplete: () => completions++));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(completions, 1);
  });
  testWidgets('an interrupted accepted scene settles once without replay', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(_scene(onComplete: () => completions++));
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 6));
    final seconds =
        (tester
                    .widget<CustomPaint>(
                      find.byKey(const Key('report-delivery-scene')),
                    )
                    .painter!
                as ReportDeliveryPainter)
            .seconds;
    expect(
      {'completions': completions, 'seconds': seconds},
      {'completions': 1, 'seconds': lessThan(5.8)},
    );
  });
  testWidgets('enabling reduced motion settles the active scene once', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(_scene(onComplete: () => completions++));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      _scene(reduced: true, onComplete: () => completions++),
    );
    await tester.pump();
    await tester.pumpWidget(_scene(onComplete: () => completions++));
    await tester.pump(const Duration(seconds: 6));
    expect(completions, 1);
  });
  testWidgets('missing target layout settles on the accepted receipt', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      _scene(bounds: Rect.zero, onComplete: () => completions++),
    );
    await tester.pump();
    expect(completions, 1);
  });
  testWidgets('disposing an accepted scene does not replay completion', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(_scene(onComplete: () => completions++));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(
      {'completions': completions, 'exception': tester.takeException()},
      {'completions': 0, 'exception': null},
    );
  });
}

Widget _scene({
  required VoidCallback onComplete,
  bool reduced = false,
  Rect bounds = const Rect.fromLTWH(20, 100, 350, 290),
}) => MaterialApp(
  theme: ReportsStyle.theme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(
    body: ReportDeliveryScene(heroBounds: bounds, onComplete: onComplete),
  ),
);

Future<void> _saveFrame(WidgetTester tester, File output) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('delivery-screen')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  if (!ready()) {
    throw StateError('The resident action did not become available');
  }
  await tester.pump();
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
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
        'X': -118.243683,
        'Y': 34.052235,
      },
      'location': {'x': -118.243683, 'y': 34.052235},
    }),
    'submitCase' => {'sCaseNumber': 'SYNTHETIC-SR-25'},
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

class _GeometryCanvas implements Canvas {
  final translations = <List<double>>[];
  final scales = <List<double>>[];

  @override
  void translate(double dx, double dy) => translations.add([dx, dy]);

  @override
  void scale(double sx, [double? sy]) => scales.add([sx, ?sy]);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
