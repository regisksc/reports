import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/design/reports_design.dart';
import 'package:shared_preferences/shared_preferences.dart';


const testStore = LocalReportStore();

void main() {
  testWidgets(
    'the report continuation cue is faint, at most five pixels, and disappears at the end',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final paths = PathProviderPlatform.instance;
      final support = Directory('.dart_tool').createTempSync('hint-');
      PathProviderPlatform.instance = _SupportPath(support.absolute.path);
      addTearDown(() async {
        PathProviderPlatform.instance = paths;
        await support.delete(recursive: true);
      });
      final outcomes = <Map<String, Object>>[];
      for (final reduced in [false, true]) {
        await tester.pumpWidget(const SizedBox());
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          MaterialApp(
            theme: ReportsStyle.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: ReportFlowPage(store: testStore,
              client: _NoSend(),
              draft: ReportDraft(
                createdAt: DateTime(2026, 10, 22),
                latitude: 34.05,
                longitude: -118.24,
                step: 3,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final hint = find.byKey(const Key('report-continuation-hint'));
        final visible = <bool>[hint.evaluate().isNotEmpty];
        final height = tester.getSize(hint).height;
        final decoration =
            tester.widget<DecoratedBox>(hint).decoration as BoxDecoration;
        final alphas = decoration.gradient!.colors
            .map((color) => color.a)
            .toList();
        final rect = tester.getRect(hint);
        await tester.pump(const Duration(seconds: 1));
        final staticRects = [rect, tester.getRect(hint)];
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        visible.add(hint.evaluate().isNotEmpty);
        await tester.drag(find.byType(ListView), const Offset(0, 1000));
        await tester.pumpAndSettle();
        visible.add(hint.evaluate().isNotEmpty);
        outcomes.add({
          'reduced': reduced,
          'height': height,
          'alphas': alphas,
          'staticRects': staticRects,
          'visible': visible,
        });
      }
      expect(outcomes, [
        for (final reduced in [false, true])
          {
            'reduced': reduced,
            'height': lessThanOrEqualTo(5),
            'alphas': everyElement(lessThanOrEqualTo(.12)),
            'staticRects': predicate<List<Rect>>(
              (rects) => rects.length == 2 && rects[0] == rects[1],
            ),
            'visible': [true, false, true],
          },
      ]);
    },
  );
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}

class _NoSend implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('No City writes');
}
