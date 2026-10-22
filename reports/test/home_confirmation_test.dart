import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/home/presentation/home_screen.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

Finder _homeResumeContinueButton() => find.descendant(
  of: find.byKey(const Key('home-resume-card')),
  matching: find.text('Continue'),
);

void main() {
  testWidgets(
    'accepted report returns Home with exact receipt and distance-based notice gestures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final originalPaths = PathProviderPlatform.instance;
      final support = Directory('.dart_tool').createTempSync('confirmation-');
      PathProviderPlatform.instance = _SupportPath(support.absolute.path);
      addTearDown(() async {
        PathProviderPlatform.instance = originalPaths;
        await support.delete(recursive: true);
      });
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final outcomes = <Map<String, Object?>>[];
      final expected = <Map<String, Object?>>[];
      for (final reduced in [false, true]) {
        copied = null;
        final observed = <String, Object?>{};
        await tester.pumpWidget(const SizedBox());
        SharedPreferences.setMockInitialValues({});
        await testStore.saveDraft(
          ReportDraft(
            createdAt: DateTime(2026, 10, 22),
            latitude: 34.052235,
            longitude: -118.243683,
            debrisLocation: 'Curb',
            quantity: '2',
            description: 'Synthetic couch, no City write',
            step: 4,
          ),
        );
        await tester.pumpWidget(
          ReportApp(
            client: PortalSubmissionClient(
              httpClient: MockClient(
                (request) async => _syntheticPortalReply(request),
              ),
            ),
          ),
        );
        await _waitFor(
          tester,
          () => _homeResumeContinueButton().evaluate().isNotEmpty,
        );
        if (reduced) {
          await tester.tap(find.byTooltip('Motion settings'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(
              CheckedPopupMenuItem<bool>,
              'Reduce motion for this session',
            ),
          );
          await tester.pumpAndSettle();
        }
        observed['effectiveReduced'] = MediaQuery.disableAnimationsOf(
          tester.element(find.byType(HomeScreen)),
        );
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
        await tester.tap(find.text('Submit'));
        await _waitFor(
          tester,
          () => find.text('SYNTHETIC-SR-21').evaluate().isNotEmpty,
        );
        observed['homeVisible'] = find.text('Start a report').evaluate().length;
        observed['cardVisible'] = find
            .byKey(const Key('home-confirmation-card'))
            .evaluate()
            .length;
        final before = (await tester.runAsync(
          testStore.loadReports,
        ))!.single.toJson();
        await tester.ensureVisible(find.text('Copy'));
        await tester.tap(find.text('Copy'));
        observed['copied'] = copied;
        await tester.tap(find.text('View receipt'));
        await tester.pumpAndSettle();
        observed['receiptVisible'] = find
            .text('Service Request: SYNTHETIC-SR-21')
            .evaluate()
            .length;
        await tester.pageBack();
        await tester.pumpAndSettle();
        final card = find.byKey(const Key('home-confirmation-card'));
        await tester.ensureVisible(card);
        final gesture = tester.widget<GestureDetector>(
          find.ancestor(of: card, matching: find.byType(GestureDetector)).first,
        );
        final width = tester.getSize(card).width;
        double x() => tester
            .widget<Transform>(
              find.byKey(const Key('confirmation-displacement')),
            )
            .transform
            .storage[12];
        double opacity() => tester
            .widget<Opacity>(find.byKey(const Key('confirmation-opacity')))
            .opacity;
        void drag(double fraction) => gesture.onHorizontalDragUpdate!(
          DragUpdateDetails(
            globalPosition: Offset.zero,
            delta: Offset(width * fraction, 0),
          ),
        );
        gesture.onHorizontalDragStart!(DragStartDetails());
        drag(.2);
        await tester.pump();
        observed['rightClamp'] = x();
        drag(-.1);
        await tester.pump();
        observed['at10'] = [x(), opacity()];
        drag(-.1);
        await tester.pump();
        observed['at20'] = [x(), opacity()];
        drag(-.15);
        await tester.pump();
        observed['at35Opacity'] = opacity();
        gesture.onHorizontalDragEnd!(
          DragEndDetails(
            velocity: const Velocity(pixelsPerSecond: Offset(-4000, 0)),
          ),
        );
        await tester.pumpAndSettle();
        observed['fastReleaseBelowThreshold'] = [x(), opacity()];
        drag(-.7);
        await tester.pump();
        observed['at70Opacity'] = opacity();
        gesture.onHorizontalDragCancel!();
        await tester.pumpAndSettle();
        observed['cancelAfterPartialFade'] = [x(), opacity()];
        drag(-1);
        await tester.pump();
        observed['at100Opacity'] = opacity();
        gesture.onHorizontalDragCancel!();
        await tester.pumpAndSettle();
        observed['cancelAtFullWidth'] = [x(), opacity()];
        drag(-.4);
        gesture.onHorizontalDragEnd!(DragEndDetails());
        await tester.pumpAndSettle();
        observed['cardAfterDismissal'] = card.evaluate().length;
        observed['storedAfterDismissal'] = (await tester.runAsync(
          testStore.loadReports,
        ))!.single.toJson();
        await tester.ensureVisible(find.text('View saved reports'));
        await tester.tap(find.text('View saved reports'));
        await _waitFor(
          tester,
          () => find.text('SYNTHETIC-SR-21').evaluate().isNotEmpty,
        );
        observed['savedReceiptVisible'] = find
            .text('SYNTHETIC-SR-21')
            .evaluate()
            .length;
        outcomes.add(observed);
        expected.add({
          'effectiveReduced': reduced,
          'homeVisible': 1,
          'cardVisible': 1,
          'copied': 'SYNTHETIC-SR-21',
          'receiptVisible': 1,
          'rightClamp': 0,
          'at10': [closeTo(-width * .1, .01), 1],
          'at20': [closeTo(-width * .2, .01), 1],
          'at35Opacity': closeTo(.8125, .001),
          'fastReleaseBelowThreshold': [0, 1],
          'at70Opacity': closeTo(.375, .001),
          'cancelAfterPartialFade': [0, 1],
          'at100Opacity': 0,
          'cancelAtFullWidth': [0, 1],
          'cardAfterDismissal': 0,
          'storedAfterDismissal': before,
          'savedReceiptVisible': 1,
        });
      }
      expect(outcomes, expected);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
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
    throw StateError('The resident action did not become available');
  }
  await tester.pumpAndSettle();
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
    'submitCase' => {'sCaseNumber': 'SYNTHETIC-SR-21'},
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
