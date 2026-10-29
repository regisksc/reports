import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = {
    'name': 'Graffiti Removal',
    'group': 'Graffiti',
    'evidence': 'anonymous available; optional attachments; advertised limit 5',
  };
  testWidgets('preview steps show a fixed action and contextual sections', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final step in [1, 2, 3, 4, 5]) {
      await tester.pumpWidget(
        MaterialApp(
          home: ServicePreviewPage(
            key: ValueKey(step),
            service: service,
            draft: {
              'id': 'one',
              'step': step,
              'description': 'Wall',
              'address': 'Main Street',
              'confirmed': true,
              'named': false,
              'photos': 0,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(Key('preview-section-$step')), findsOneWidget);
      if (step == 1) {
        expect(
          find.bySemanticsLabel('Illustrative location pin, not a live map'),
          findsOneWidget,
        );
      }
      if (step == 2) {
        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      }
      if (step == 3) {
        expect(find.text('Anonymous'), findsOneWidget);
      }
      if (step == 4) {
        expect(find.text('Location'), findsWidgets);
      }
      if (step == 5) {
        expect(find.text('Local lookup ID'), findsOneWidget);
      }
      if (step < 5) {
        expect(find.byKey(const Key('preview-action-footer')), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
  testWidgets('contact choices stack at large text on a narrow phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const ServicePreviewPage(
          service: service,
          draft: {'id': 'one', 'step': 3, 'named': false},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Anonymous')).dy,
      lessThan(tester.getTopLeft(find.text('Provide contact details')).dy),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('fixed action remains visible above the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicePreviewPage(
          service: service,
          draft: {'id': 'one', 'step': 0},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(340));
    expect(tester.getTopLeft(button).dy, greaterThan(200));
    expect(tester.takeException(), isNull);
  });
}
