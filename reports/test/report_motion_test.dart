import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/features/home/presentation/accepted_home_hero.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

Finder _homeResumeContinueButton() => find.descendant(
  of: find.byKey(const Key('home-resume-card')),
  matching: find.text('Continue'),
);

void main() {
  test('extracted accepted hero controls preserve their widget key', () {
    const key = ValueKey('accepted-hero-controls');
    expect(const AcceptedHeroControls(key: key).key, key);
  });

  testWidgets(
    'a resident moves through a retained report with purposeful or stationary motion',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final originalPaths = PathProviderPlatform.instance;
      final directory = Directory('.dart_tool').createTempSync('motion-');
      PathProviderPlatform.instance = _SupportPath(directory.absolute.path);
      addTearDown(() async {
        PathProviderPlatform.instance = originalPaths;
        await directory.delete(recursive: true);
      });
      final outcomes = <Object>[];
      for (final mode in ['normal', 'system', 'session']) {
        await tester.pumpWidget(const SizedBox.shrink());
        SharedPreferences.setMockInitialValues({});
        await testStore.saveDraft(
          ReportDraft(
            createdAt: DateTime(2026, 10, 22),
            latitude: 34.052235,
            longitude: -118.243683,
            debrisLocation: 'Curb',
            quantity: '2',
            step: 1,
          ),
        );
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(reduceMotion: mode == 'system');
        await tester.pumpWidget(ReportApp(client: _NoCityWrites()));
        await _waitFor(
          tester,
          () => _homeResumeContinueButton().evaluate().isNotEmpty,
        );
        if (mode == 'session') {
          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(SwitchListTile, 'Reduce motion'),
          );
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(_homeResumeContinueButton());
        await tester.pumpAndSettle();
        final hero = tester.getRect(find.text('Report a problem.'));
        final movements = <Object>[];
        Future<void> change(Finder action, Finder arriving) async {
          await tester.pumpAndSettle();
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          final start = tester.getTopLeft(arriving);
          await tester.pump(const Duration(milliseconds: 80));
          final middle = tester.getTopLeft(arriving);
          await tester.pumpAndSettle();
          final end = tester.getTopLeft(arriving);
          movements.add({
            'verticalTravel': [start.dy - end.dy, middle.dy - end.dy],
            'horizontalTravel': [start.dx - end.dx, middle.dx - end.dx],
          });
        }

        await change(_homeResumeContinueButton(), find.text('New report'));
        await _waitFor(
          tester,
          () =>
              tester
                  .widget<TextField>(find.byKey(const Key('report-quantity')))
                  .enabled ==
              true,
        );
        await change(
          find.text('Continue'),
          find.text('A little context helps.'),
        );
        await change(
          find.text('Skip photo'),
          find.text('Describe the dumped items (optional)'),
        );
        await tester.enterText(
          find.byKey(const Key('report-description')),
          'Synthetic motion check: couch beside the curb.',
        );
        await change(
          find.text('Continue'),
          find.text('Without contact details'),
        );
        await tester.tap(find.text('Without contact details'));
        await tester.pumpAndSettle();
        await change(find.text('Continue'), find.text('Edit Location'));
        final review = [
          for (final text in [
            '34.052235, -118.243683',
            '2 items · Curb',
            'No photo added',
            'Synthetic motion check: couch beside the curb.',
          ])
            tester.widget<Text>(find.text(text)).data,
        ];
        await change(
          find.text('Edit Items'),
          find.text('Where is the debris?'),
        );
        final quantity = tester
            .widget<TextField>(find.byKey(const Key('report-quantity')))
            .controller!
            .text;
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Edit Items'), findsOneWidget);
        for (var step = 0; step < 5; step++) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byType(BackButton));
        await tester.pump();
        final returningHero = find.text(
          'Report a problem.',
          skipOffstage: false,
        );
        final returningGeometry = [tester.getRect(returningHero)];
        await tester.pump(const Duration(milliseconds: 80));
        returningGeometry.add(tester.getRect(returningHero));
        await tester.pumpAndSettle();
        returningGeometry.add(tester.getRect(returningHero));
        outcomes.add({
          'mode': mode,
          'movements': movements,
          'review': review,
          'quantityAfterEdit': quantity,
          'heroPreserved': returningGeometry
              .map((rect) => rect == hero)
              .toList(),
          'exception': tester.takeException(),
        });
      }
      expect(outcomes, [
        for (final mode in ['normal', 'system', 'session'])
          {
            'mode': mode,
            'movements': [
              for (var change = 0; change < 6; change++)
                {
                  'verticalTravel': mode == 'normal'
                      ? [
                          greaterThanOrEqualTo(48),
                          allOf(greaterThan(0), lessThan(48)),
                        ]
                      : [0, 0],
                  'horizontalTravel': [closeTo(0, .1), closeTo(0, .1)],
                },
            ],
            'review': [
              '34.052235, -118.243683',
              '2 items · Curb',
              'No photo added',
              'Synthetic motion check: couch beside the curb.',
            ],
            'quantityAfterEdit': '2',
            'heroPreserved': [true, true, true],
            'exception': null,
          },
      ]);
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

class _NoCityWrites implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('The synthetic motion journey must not send reports');
}
