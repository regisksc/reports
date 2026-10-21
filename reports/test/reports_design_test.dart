import 'package:reports/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';

void main() {
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
      Future<void> select(String label) async {
        await tester.tap(find.byTooltip('Motion settings'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(CheckedPopupMenuItem<bool>, label),
        );
        await tester.pumpAndSettle();
      }

      expect(reduced(), isTrue);
      platform.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpAndSettle();
      expect(reduced(), isFalse);
      await select('Reduce motion for this session');
      expect(reduced(), isTrue);
      platform.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(reduced(), isTrue);
      await select('Follow device settings');
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
      await tester.tap(find.byTooltip('Motion settings'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<bool>,
          'Reduce motion for this session',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help and information'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final initialPosition = tester.getTopLeft(find.text('Good to know'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getTopLeft(find.text('Good to know')), initialPosition);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Good to know')), initialPosition);
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
    expect(find.byTooltip('Motion settings'), findsOneWidget);
  });

  testWidgets(
    'motion settings can reduce motion for the session and follow the device again',
    (tester) async {
      await tester.pumpWidget(const ReportApp());
      await tester.tap(find.byTooltip('Motion settings'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<bool>,
          'Reduce motion for this session',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byType(HomeScreen))),
        isTrue,
      );

      await tester.tap(find.byTooltip('Motion settings'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<bool>,
          'Follow device settings',
        ),
      );
      await tester.pumpAndSettle();
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
    await tester.tap(find.text('Help and information'));
    await tester.pumpAndSettle();

    expect(find.text('Good to know'), findsOneWidget);
    expect(find.text('Reports go to MyLA311'), findsOneWidget);
    expect(find.text('No account needed'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Keep your Service Request number'),
      200,
    );
    expect(find.text('Keep your Service Request number'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Report illegal dumping.'), findsOneWidget);
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
      expect(find.text('Report illegal dumping.'), findsOneWidget);
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
