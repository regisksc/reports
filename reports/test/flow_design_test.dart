import 'package:reports/features/report/data/local_report_store.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/design/reports_design.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = LocalReportStore();

void main() {
  testWidgets(
    'the report begins at a location step with progress gated by GPS',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          theme: ReportsStyle.theme,
          home: ReportFlowPage(store: testStore, client: _NoSubmissionClient()),
        ),
      );
      await tester.pump();

      expect(find.text('Where did you spot it?'), findsOneWidget);
      expect(find.text('Step 1 of 5 · Location'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .minHeight,
        10,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      expect(find.text('Submit'), findsNothing);
    },
  );

  testWidgets('reduced motion removes report content and progress animations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ReportFlowPage(
            store: testStore,
            client: _NoSubmissionClient(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byType(TweenAnimationBuilder<double>),
          )
          .duration,
      Duration.zero,
    );
  });
}

class _NoSubmissionClient implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('Design checks must not send reports');
}
