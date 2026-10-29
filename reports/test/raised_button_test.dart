import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:reports/design/reports_design.dart';

void main() {
  testWidgets(
    'primary press feedback respects Home styling, motion and availability',
    (tester) async {
      {
        await tester.pumpWidget(const ReportApp());
        final button = find.widgetWithText(FilledButton, 'Start a report');
        final face = find.descendant(
          of: button,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.white,
          ),
        );
        final hero = tester.getRect(find.byKey(const Key('home-hero')));
        final buttonRect = tester.getRect(button);
        final restingFace = tester.getRect(face);
        final restingLabel = tester.getTopLeft(find.text('Start a report'));
        expect(
          tester.widget<DecoratedBox>(face).decoration,
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
              BorderSide(color: ReportsStyle.orangeDark, width: 2),
            ),
            boxShadow: const [
              BoxShadow(color: ReportsStyle.orangeDark, offset: Offset(0, 4)),
            ],
          ),
        );

        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          tester.getRect(face),
          Rect.fromLTRB(
            restingFace.left,
            restingFace.top + 3,
            restingFace.right,
            restingFace.bottom,
          ),
        );
        expect(
          tester.getTopLeft(find.text('Start a report')),
          restingLabel + const Offset(0, 1.5),
        );
        expect(
          tester.widget<DecoratedBox>(face).decoration,
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(
              BorderSide(color: ReportsStyle.orangeDark, width: 2),
            ),
            boxShadow: const [
              BoxShadow(color: ReportsStyle.orangeDark, offset: Offset(0, 1)),
            ],
          ),
        );
        expect(tester.getRect(button), buttonRect);
        expect(tester.getRect(find.byKey(const Key('home-hero'))), hero);

        await gesture.cancel();
        await tester.pumpAndSettle();

        expect(tester.getRect(face), restingFace);
        expect(tester.getTopLeft(find.text('Start a report')), restingLabel);
        expect(find.text('Report a problem.'), findsOneWidget);
      }
      {
        var actions = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ReportsStyle.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => FilledButton(
                  onPressed: () => setState(() => actions++),
                  child: Text('Continue $actions'),
                ),
              ),
            ),
          ),
        );
        final button = find.byType(FilledButton);
        final face = find.descendant(
          of: button,
          matching: find.byType(DecoratedBox),
        );
        final restingFace = tester.getRect(face);
        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(
          tester.getRect(face),
          Rect.fromLTRB(
            restingFace.left,
            restingFace.top + 3,
            restingFace.right,
            restingFace.bottom,
          ),
        );
        expect(find.text('Continue 0'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.getRect(face), restingFace);
        expect(find.text('Continue 1'), findsOneWidget);
      }
      {
        await tester.pumpWidget(
          MaterialApp(
            theme: ReportsStyle.theme,
            home: const Scaffold(
              body: FilledButton(onPressed: null, child: Text('Unavailable')),
            ),
          ),
        );
        final face = find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(DecoratedBox),
        );
        final restingFace = tester.getRect(face);
        final decoration = BoxDecoration(
          color: ReportsStyle.border,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [],
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Unavailable')),
        );
        await tester.pumpAndSettle();

        expect(tester.getRect(face), restingFace);
        expect(tester.widget<DecoratedBox>(face).decoration, decoration);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.getRect(face), restingFace);
        expect(tester.widget<DecoratedBox>(face).decoration, decoration);
        expect(find.text('Unavailable'), findsOneWidget);
      }
    },
  );
  testWidgets('custom shadow color keeps raised press feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ReportsStyle.theme,
        home: Scaffold(
          body: OutlinedButton(
            style: ReportsStyle.raisedButtonStyle(
              backgroundColor: Colors.white,
              shadowColor: ReportsStyle.border,
            ),
            onPressed: () {},
            child: const Text('Choice'),
          ),
        ),
      ),
    );
    final button = find.widgetWithText(OutlinedButton, 'Choice');
    final face = find.descendant(
      of: button,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.white,
      ),
    );
    final resting = tester.getRect(face);
    BoxShadow shadow() =>
        (tester.widget<DecoratedBox>(face).decoration as BoxDecoration)
            .boxShadow!
            .single;
    expect(shadow().color, ReportsStyle.border);
    expect(shadow().offset, const Offset(0, 4));
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(face).top, resting.top + 3);
    expect(shadow().color, ReportsStyle.border);
    expect(shadow().offset, const Offset(0, 1));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getRect(face), resting);
  });
}
