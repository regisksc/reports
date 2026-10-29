import 'package:reports/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _setMotion(WidgetTester tester, bool enabled) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  final control = find.widgetWithText(SwitchListTile, 'Reduce motion');
  if (tester.widget<SwitchListTile>(control).value != enabled) {
    await tester.tap(control);
  }
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'device motion changes remain authoritative with a session override',
    (tester) async {
      final platform = tester.platformDispatcher;
      addTearDown(platform.clearAccessibilityFeaturesTestValue);
      platform.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        reduceMotion: true,
      );
      await tester.pumpWidget(const ReportApp());
      bool reduced() => MediaQuery.disableAnimationsOf(
        tester.element(find.byType(HomeScreen)),
      );

      expect(reduced(), isTrue);
      platform.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpAndSettle();
      expect(reduced(), isFalse);
      await _setMotion(tester, true);
      expect(reduced(), isTrue);
      platform.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(reduced(), isTrue);
      await _setMotion(tester, false);
      expect(reduced(), isTrue);
      platform.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpAndSettle();
      expect(reduced(), isFalse);
      platform.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      expect(reduced(), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      platform.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'session reduced motion keeps iOS page navigation stationary',
    (tester) async {
      await tester.pumpWidget(const ReportApp());
      await _setMotion(tester, true);
      await tester.ensureVisible(find.text('Help and information'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help and information'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final initialPosition = tester.getTopLeft(
        find.text('Let’s clear things up.'),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.getTopLeft(find.text('Let’s clear things up.')),
        initialPosition,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Let’s clear things up.')),
        initialPosition,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('the home stays readable on a narrow phone with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ReportApp());

    expect(tester.takeException(), isNull);
    expect(find.text('Start a report'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets(
    'motion settings can reduce motion for the session and follow the device again',
    (tester) async {
      await tester.pumpWidget(const ReportApp());
      await _setMotion(tester, true);
      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byType(HomeScreen))),
        isTrue,
      );

      await _setMotion(tester, false);
      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byType(HomeScreen))),
        isFalse,
      );
    },
  );

  testWidgets('body text uses the bundled reference font offline', (
    tester,
  ) async {
    await tester.pumpWidget(const ReportApp());
    final theme = Theme.of(tester.element(find.byType(HomeScreen)));

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Mona Sans');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Helvetica Neue');
    final font = await rootBundle.load('assets/fonts/MonaSans.ttf');
    expect(font.lengthInBytes, greaterThan(10000));
  });

  testWidgets('help explains real anonymous reporting from the home action', (
    tester,
  ) async {
    await tester.pumpWidget(const ReportApp());
    await tester.ensureVisible(find.text('Help and information'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help and information'));
    await tester.pumpAndSettle();

    expect(find.text('Let’s clear things up.'), findsOneWidget);
    await tester.tap(find.text('How reporting works'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Illegal dumping can be submitted to the City'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Other service flows are local previews'),
      findsOneWidget,
    );
    expect(find.textContaining('No account is needed'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drafts, receipts & interrupted sends'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Check the original request before trying again'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Keep your Service Request number'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Report a problem.'), findsOneWidget);
  });

  testWidgets(
    'the home shows its Report Pop logo and orange hero at phone width',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const ReportApp());

      expect(find.byKey(const ValueKey('reports-brand-logo')), findsOneWidget);
      expect(find.text('Report a problem.'), findsOneWidget);
      expect(find.text('Start a report'), findsOneWidget);
      expect(find.text('View saved reports'), findsOneWidget);
      expect(find.text('A few simple steps'), findsOneWidget);
      final hero = tester.widget<Container>(find.byKey(const Key('home-hero')));
      expect(
        (hero.decoration! as BoxDecoration).color,
        const Color(0xffff9600),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the app uses the reference orange and outlined design system', (
    tester,
  ) async {
    await tester.pumpWidget(const ReportApp());
    final theme = Theme.of(tester.element(find.byType(HomeScreen)));

    expect(theme.colorScheme.primary, const Color(0xffff9600));
    expect(theme.colorScheme.onSurface, const Color(0xff3c3c3c));
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.inputDecorationTheme.fillColor, const Color(0xfff7f7f7));
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 52),
    );
  });
}
