import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/account/account_page.dart';
import 'package:reports/features/account/help_page.dart';
import 'package:reports/features/account/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings starts with the account card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Your account')).dy,
      lessThan(tester.getTopLeft(find.text('Make yourself comfortable')).dy),
    );
  });

  testWidgets('help topics show icons and articles link to all topics', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('What this preview can do'), findsOneWidget);
    await tester.tap(find.text('How reporting works'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    await tester.tap(find.text('All help topics'));
    await tester.pumpAndSettle();
    expect(find.text('Let’s clear things up.'), findsOneWidget);
  });

  testWidgets(
    'direct help article opens all topics without a duplicate article',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const HelpPage(initialArticle: 'privacy'),
                ),
              ),
              child: const Text('Open article'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open article'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All help topics'));
      await tester.pumpAndSettle();
      expect(find.text('Let’s clear things up.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open article'), findsOneWidget);
    },
  );

  testWidgets(
    'account form keeps labels visible and offers account navigation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
        ),
      );
      await tester.tap(find.text('Sign in to demo'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, 'Forgot password?'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Create account'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'alex@example.com',
      );
      expect(find.text('Email'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Account'));
      await tester.pumpAndSettle();
      expect(find.text('Your account'), findsOneWidget);
    },
  );
  testWidgets('direct service registration returns to its service', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const DemoSignInPage()),
            ),
            child: const Text('Service information'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Service information'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to service'));
    await tester.pumpAndSettle();
    expect(find.text('Service information'), findsOneWidget);
  });
  testWidgets('recovery link returns to the sign-in form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Sign in to demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Continue in demo'), findsOneWidget);
    expect(find.text('Recover access'), findsNothing);
  });
  testWidgets('help icons sit on pale tiles and the note is shaded', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    final tile = find.ancestor(
      of: find.byIcon(Icons.article_outlined),
      matching: find.byType(DecoratedBox),
    );
    expect(
      tester
          .widgetList<DecoratedBox>(tile)
          .any(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).color ==
                    const Color(0xfff7f7f7),
          ),
      isTrue,
    );
    final note = tester.widget<Card>(
      find
          .ancestor(
            of: find.text('What this preview can do'),
            matching: find.byType(Card),
          )
          .first,
    );
    expect(note.color, const Color(0xfff7f7f7));
  });

  testWidgets('settings links show direction arrows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    final account = find.ancestor(
      of: find.text('Account'),
      matching: find.byType(OutlinedButton),
    );
    expect(
      find.descendant(of: account, matching: find.byIcon(Icons.arrow_forward)),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('About permissions'), 200);
    final permissions = find.ancestor(
      of: find.text('About permissions'),
      matching: find.byType(TextButton),
    );
    expect(
      find.descendant(
        of: permissions,
        matching: find.byIcon(Icons.arrow_forward),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign-in actions wrap and field labels stay bold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Sign in to demo'));
    await tester.pumpAndSettle();
    final label = tester.widget<Text>(find.text('Email'));
    expect(label.style?.fontWeight, FontWeight.w700);
    final actions = find.ancestor(
      of: find.text('Forgot password?'),
      matching: find.byType(Wrap),
    );
    expect(
      find.descendant(of: actions.first, matching: find.text('Create account')),
      findsOneWidget,
    );
  });
  testWidgets('account form actions fit narrow large-text layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('Sign in to demo'), 200);
    await tester.ensureVisible(find.text('Sign in to demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to demo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Create account'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
