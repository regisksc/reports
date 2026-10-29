import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/native_app_test_support.dart';

void main() {
  testWidgets('only the selected item family has orange depth', (tester) async {
    await _openItems(tester);
    Color depthOf(String label) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(OutlinedButton),
      );
      final surface = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: button,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .singleWhere(
            (decoration) => decoration.boxShadow?.isNotEmpty == true,
          );
      return surface.boxShadow!.single.color;
    }

    final unselected = depthOf('Electronic Waste');
    await tester.tap(find.text('Electronic Waste'));
    await tester.pumpAndSettle();
    expect(
      {
        'unselected': unselected,
        'selected': depthOf('Electronic Waste'),
        'other family': depthOf('Bulky Items'),
      },
      {
        'unselected': ReportsStyle.border,
        'selected': ReportsStyle.orangeDark,
        'other family': ReportsStyle.border,
      },
    );
  });

  testWidgets('legacy saved draft keeps its placement and count edits', (
    tester,
  ) async {
    final store = await _openItems(tester);
    final placement = find.byType(DropdownButtonFormField<String>);
    await _show(tester, placement);
    await tester.tap(placement);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alley').last);
    await tester.pumpAndSettle();
    final quantity = find.byKey(const Key('report-quantity'));
    await _show(tester, quantity);
    await tester.enterText(quantity, '3');
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(
      {
        'family': store.draft?.itemFamily,
        'placement': store.draft?.debrisLocation,
        'quantity': store.draft?.quantity,
        'returned': find.text('Open draft').evaluate().length,
      },
      {'family': null, 'placement': 'Alley', 'quantity': '3', 'returned': 1},
    );
  });

  testWidgets('item family and per-item answers survive Save and close', (
    tester,
  ) async {
    final store = await _openItems(tester);
    await tester.tap(find.text('Electronic Waste'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Computers'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Computers'));
    await tester.tap(find.text('Computers'));
    await tester.pumpAndSettle();
    final quantity = find.byKey(const ValueKey('item-quantity-Computers'));
    await tester.scrollUntilVisible(
      quantity,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '2');
    final placement = find.byKey(const ValueKey('item-location-Computers'));
    await tester.ensureVisible(placement);
    await tester.tap(placement);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curb').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(
      {
        'returned': find.text('Open draft').evaluate().length,
        'family': store.draft?.itemFamily,
        'items': store.draft?.items.map((item) => item.toJson()).toList(),
      },
      {
        'returned': 1,
        'family': 'Electronic Waste',
        'items': [
          {'name': 'Computers', 'quantity': '2', 'location': 'Curb'},
        ],
      },
    );
  });

  testWidgets('item search and expansion stay within the chosen family', (
    tester,
  ) async {
    await _openItems(tester);
    await tester.tap(find.text('Bulky Items'));
    await tester.pumpAndSettle();
    await _show(tester, find.text('Show all 40 items'));
    await tester.tap(find.text('Show all 40 items'));
    await tester.pumpAndSettle();
    final expanded = find.text('Bed Frame (Wood)').evaluate().length;
    await _show(tester, find.text('Show fewer items'));
    await tester.tap(find.text('Show fewer items'));
    await tester.pumpAndSettle();
    final collapsed = find.text('Bed Frame (Wood)').evaluate().length;
    final search = find.byKey(const ValueKey('item-search-Bulky Items'));
    await _show(tester, search);
    await tester.enterText(search, 'Bed Frame');
    await tester.pumpAndSettle();
    final filtered = find.text('Bed Frame (Wood)').evaluate().length;
    await tester.enterText(search, 'no matching item');
    await tester.pumpAndSettle();
    final empty = find
        .text('No matching items. Try another search.')
        .evaluate()
        .length;
    await _show(tester, find.text('Metal/Household Appliances'));
    await tester.tap(find.text('Metal/Household Appliances'));
    await tester.pumpAndSettle();
    expect(
      {
        'expanded': expanded,
        'collapsed': collapsed,
        'filtered': filtered,
        'empty': empty,
        'newFamily': find.text('Scrap Metal').evaluate().length,
      },
      {
        'expanded': 1,
        'collapsed': 0,
        'filtered': 1,
        'empty': 1,
        'newFamily': 1,
      },
    );
  });

  testWidgets('invalid item quantity blocks Continue with useful feedback', (
    tester,
  ) async {
    await _openItems(tester);
    await tester.tap(find.text("I'm not sure"));
    await tester.pumpAndSettle();
    await _show(tester, find.widgetWithText(OutlinedButton, 'Tires'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tires'));
    await tester.pumpAndSettle();
    final placement = find.byKey(const ValueKey('item-location-Tires'));
    await _show(tester, placement);
    await tester.tap(placement);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curb').last);
    await tester.pumpAndSettle();
    final quantity = find.byKey(const ValueKey('item-quantity-Tires'));
    await _show(tester, quantity);
    await tester.enterText(quantity, '0');
    await tester.pumpAndSettle();
    expect(
      {
        'error': find.text('Enter a number from 1 to 999.').evaluate().length,
        'canContinue':
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Continue'),
                )
                .onPressed !=
            null,
      },
      {'error': 1, 'canContinue': false},
    );
  });

  testWidgets('an item selection can be removed from the saved draft', (
    tester,
  ) async {
    final store = await _openItems(tester);
    await tester.tap(find.text('Bulky Items'));
    await tester.pumpAndSettle();
    final choice = find.widgetWithText(OutlinedButton, 'Mattress');
    await _show(tester, choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    await _show(tester, choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(store.draft?.items, isEmpty);
  });

  testWidgets('item choices fit a narrow phone with doubled text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openItems(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed item choice loading can be retried', (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.evict('assets/illegal_dumping_items.json');
    });
    await _openItems(tester, preloadCatalog: false);
    final failure = find
        .text('Item choices could not be loaded.')
        .evaluate()
        .length;
    messenger.setMockMessageHandler('flutter/assets', null);
    rootBundle.evict('assets/illegal_dumping_items.json');
    await tester.runAsync(
      () => rootBundle.loadString('assets/illegal_dumping_items.json'),
    );
    await tester.tap(find.text('Try again'));
    for (
      var turn = 0;
      turn < 100 && find.text('Electronic Waste').evaluate().isEmpty;
      turn++
    ) {
      await tester.runAsync(() => Future<void>(() {}));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(
      {
        'failure': failure,
        'loaded': find.text('Electronic Waste').evaluate().length,
      },
      {'failure': 1, 'loaded': 1},
    );
  });
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
}

Future<MemoryReportStore> _openItems(
  WidgetTester tester, {
  bool preloadCatalog = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  rootBundle.evict('assets/illegal_dumping_items.json');
  if (preloadCatalog) {
    await tester.runAsync(
      () => rootBundle.loadString('assets/illegal_dumping_items.json'),
    );
  }
  final store = MemoryReportStore();
  await tester.pumpWidget(
    MaterialApp(
      theme: ReportsStyle.theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ReportFlowPage(
                  store: store,
                  client: NoSubmissionClient(),
                  draft: ReportDraft(
                    createdAt: DateTime(2026, 10, 28),
                    flowVersion: 2,
                    step: 1,
                    latitude: 34.0522,
                    longitude: -118.2437,
                  ),
                ),
              ),
            ),
            child: const Text('Open draft'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open draft'));
  for (
    var turn = 0;
    turn < 100 && find.text('Electronic Waste').evaluate().isEmpty;
    turn++
  ) {
    await tester.runAsync(() => Future<void>(() {}));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  return store;
}
