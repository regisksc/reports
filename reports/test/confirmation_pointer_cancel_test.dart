import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/home/presentation/home_confirmation_card.dart';
import 'package:reports/design/reports_design.dart';

const _number = 'SYNTHETIC-RETAINED-CANCEL';

void main() {
  testWidgets(
    'a recognized held swipe travels beyond 40 percent and partially fades',
    (tester) async {
      await tester.pumpWidget(
        _presentation(onViewReceipt: () {}, onDismissed: () {}),
      );
      final original = tester.getRect(
        find.byKey(const Key('home-confirmation-card')),
      );
      TestGesture? gesture;
      addTearDown(() async {
        await gesture?.cancel();
        await tester.pumpAndSettle();
      });
      gesture = await _holdFadedSwipe(tester);
      final held = tester.getRect(
        find.byKey(const Key('home-confirmation-card')),
      );
      final faded = tester
          .widget<Opacity>(find.byKey(const Key('confirmation-opacity')))
          .opacity;
      expect(
        {
          'heldLeft': held.center.dx < original.center.dx - original.width * .4,
          'faded': faded,
        },
        {'heldLeft': true, 'faded': inExclusiveRange(0, .5)},
      );
    },
  );

  testWidgets(
    'cancelling a recognized faded swipe recenters at full opacity without dismissal',
    (tester) async {
      var dismissals = 0;
      await tester.pumpWidget(
        _presentation(onViewReceipt: () {}, onDismissed: () => dismissals++),
      );
      final card = find.byKey(const Key('home-confirmation-card'));
      final original = tester.getRect(card);
      final gesture = await _holdFadedSwipe(tester);
      await gesture.cancel();
      await tester.pumpAndSettle();
      final present = card.evaluate().isNotEmpty;
      expect(
        {
          'dismissals': dismissals,
          'restored': present ? tester.getRect(card) : null,
          'opacity': present
              ? tester
                    .widget<Opacity>(
                      find.byKey(const Key('confirmation-opacity')),
                    )
                    .opacity
              : null,
        },
        {'dismissals': 0, 'restored': original, 'opacity': 1.0},
      );
    },
  );

  testWidgets(
    'View receipt remains available with the exact SR after pointer cancellation',
    (tester) async {
      var receiptOpens = 0;
      await tester.pumpWidget(
        _presentation(onViewReceipt: () => receiptOpens++, onDismissed: () {}),
      );
      final gesture = await _holdFadedSwipe(tester);
      await gesture.cancel();
      await tester.pumpAndSettle();
      await tester.tap(find.text('View receipt'));
      expect(
        {
          'receiptOpens': receiptOpens,
          'number': find.text(_number).evaluate().length,
        },
        {'receiptOpens': 1, 'number': 1},
      );
    },
  );
}

Future<TestGesture> _holdFadedSwipe(WidgetTester tester) async {
  final original = tester.getRect(
    find.byKey(const Key('home-confirmation-card')),
  );
  final gesture = await tester.startGesture(original.center);
  await gesture.moveBy(const Offset(-30, 0));
  await tester.pump();
  await gesture.moveBy(Offset(-original.width * .7, 0));
  await tester.pump();
  return gesture;
}

Widget _presentation({
  required VoidCallback onViewReceipt,
  required VoidCallback onDismissed,
}) => MaterialApp(
  theme: ReportsStyle.theme,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 350,
        child: HomeConfirmationCard(
          serviceRequestNumber: _number,
          onViewReceipt: onViewReceipt,
          onDismissed: onDismissed,
        ),
      ),
    ),
  ),
);
