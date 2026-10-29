import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/account/settings_page.dart';
import 'package:reports/features/account/account_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

Finder accountField(String label) => find.descendant(
  of: find.bySemanticsLabel(label),
  matching: find.byType(TextFormField),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings changes motion through its callback', (tester) async {
    bool? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          onMotionChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump();
    expect(changed, isTrue);
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('account registration saves only local profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create demo account'));
    await tester.pumpAndSettle();
    await tester.enterText(accountField('Name'), 'Alex');
    await tester.enterText(accountField('Email'), 'alex@example.com');
    await tester.tap(find.text('Create local profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Demo profile saved locally. No City account was changed.'),
      findsOneWidget,
    );
    expect(find.text('Your account'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('reports_local_profile_v1')!), {
      'name': 'Alex',
      'email': 'alex@example.com',
    });
  });

  testWidgets('clear confirmation preserves real reports', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reports_v2': ['real'],
      'reports_local_profile_v1': '{}',
    });
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          onMotionChanged: (_) {},
          onClearLocalData: () async {
            cleared = true;
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 300);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('reports_v2'), ['real']);
    expect(prefs.getString('reports_local_profile_v1'), isNull);
    expect(cleared, isTrue);
  });
  testWidgets(
    'recovery does not send an email and sign in does not store passwords',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in to demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(accountField('Email'), 'alex@example.com');
      await tester.tap(find.text('Preview recovery'));
      await tester.pumpAndSettle();
      expect(find.text('Demo only: no email was sent.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(accountField('Email'), 'alex@example.com');
      await tester.enterText(accountField('Demo password'), 'example');
      await tester.tap(find.text('Continue in demo'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('reports_local_profile_v1'),
        isNot(contains('example"')),
      );
    },
  );

  testWidgets('help opens an article with real submission guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('Help'), 300);
    await tester.ensureVisible(find.text('Help'));
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How reporting works'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Illegal dumping can be submitted'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'No account is needed for an illegal-dumping report.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('forget contact keeps submitted records', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reports_v2': ['receipt'],
      'reports_saved_contact_v1':
          '{"first":"Alex","last":"Doe","email":"a@example.com","phone":""}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Forget saved contact'), 200);
    await tester.ensureVisible(find.text('Forget saved contact'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alex Doe'), findsOneWidget);
    await tester.tap(find.text('Forget saved contact'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reports_saved_contact_v1'), isNull);
    expect(prefs.getStringList('reports_v2'), ['receipt']);
  });

  testWidgets('profile reads and updates local information', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reports_local_profile_v1': '{"name":"Alex","email":"a@example.com"}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    await tester.enterText(accountField('Display name'), 'Taylor');
    await tester.tap(find.text('Save demo profile'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      jsonDecode(prefs.getString('reports_local_profile_v1')!)['name'],
      'Taylor',
    );
  });

  testWidgets('registration requires name and email', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create demo account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create local profile'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter an email'), findsOneWidget);
  });
  testWidgets('settings links explain permissions and privacy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('About permissions'), 200);
    await tester.ensureVisible(find.text('About permissions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About permissions'));
    await tester.pumpAndSettle();
    expect(find.text('Location & photo permissions'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('How local information is kept'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How local information is kept'));
    await tester.pumpAndSettle();
    expect(find.text('Your information & privacy'), findsOneWidget);
  });

  testWidgets('cancel dialogs keeps preview data', (tester) async {
    SharedPreferences.setMockInitialValues({'reports_local_profile_v1': '{}'});
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'reports_local_profile_v1',
      ),
      '{}',
    );
  });

  testWidgets(
    'account provides preferences, help and registration from sign in',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preferences & accessibility'));
      await tester.pumpAndSettle();
      expect(find.text('Reduce motion'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      expect(find.text('Let’s clear things up.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in to demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Create local profile'), findsOneWidget);
    },
  );
  testWidgets('motion stays synchronized across account preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferences & accessibility'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferences & accessibility'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
  });
  testWidgets(
    'demo updates preference is local and does not send notifications',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preferences & accessibility'));
      await tester.pumpAndSettle();
      expect(
        find.text('Notifications are not sent in this preview.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Updates for demo reports'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'reports_demo_updates_v1',
        ),
        isTrue,
      );
    },
  );
  testWidgets('clear resets motion and demo updates', (tester) async {
    SharedPreferences.setMockInitialValues({'reports_demo_updates_v1': true});
    bool? motion;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: true,
          showDemoUpdates: true,
          onMotionChanged: (value) => motion = value,
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    expect(motion, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_demo_updates_v1',
      ),
      isNull,
    );
    await tester.scrollUntilVisible(find.text('Reduce motion'), -200);
    await tester.ensureVisible(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(SwitchListTile, 'Reduce motion'),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isFalse,
    );
  });
  testWidgets('clear failure is shown without a success message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          onMotionChanged: (_) {},
          onClearLocalData: () async {
            throw StateError('failed');
          },
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not clear all preview data. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Local preview data cleared.'), findsNothing);
  });
  testWidgets('failed forgetting contact is reported', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingRemoveStore({
      'flutter.reports_saved_contact_v1':
          '{"first":"Alex","last":"Doe","email":"a@example.com","phone":""}',
    });
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Forget saved contact'), 200);
    await tester.ensureVisible(find.text('Forget saved contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget saved contact'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not forget contact. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('failed preference removal is reported', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingProfileRemoveStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not clear all preview data. Please try again.'),
      findsOneWidget,
    );
  });
  testWidgets('profile save failure is shown', (tester) async {
    SharedPreferencesStorePlatform.instance = _FailingSetStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create demo account'));
    await tester.pumpAndSettle();
    await tester.enterText(accountField('Name'), 'Alex');
    await tester.enterText(accountField('Email'), 'a@example.com');
    await tester.tap(find.text('Create local profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save the demo profile. Please try again.'),
      findsOneWidget,
    );
  });
  testWidgets('thrown profile save error is shown', (tester) async {
    SharedPreferencesStorePlatform.instance = _ThrowingSetStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create demo account'));
    await tester.pumpAndSettle();
    await tester.enterText(accountField('Name'), 'Alex');
    await tester.enterText(accountField('Email'), 'a@example.com');
    await tester.tap(find.text('Create local profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save the demo profile. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('failed demo updates save restores previous setting', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _FailingSetStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          showDemoUpdates: true,
          onMotionChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Updates for demo reports'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save the preference. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(
                SwitchListTile,
                'Updates for demo reports',
              ),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isFalse,
    );
  });
  testWidgets('late profile restore does not overwrite edits', (tester) async {
    final store = _DelayedStore({
      'flutter.reports_local_profile_v1':
          '{"name":"Old","email":"old@example.com"}',
    });
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(accountField('Display name'), 'New');
    store.ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('corrupt profile data does not crash profile', (tester) async {
    SharedPreferences.setMockInitialValues({'reports_local_profile_v1': '{'});
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the demo profile.'), findsOneWidget);
  });
  testWidgets('late settings restore does not overwrite an update choice', (
    tester,
  ) async {
    final store = _DelayedStore({'flutter.reports_demo_updates_v1': false});
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          showDemoUpdates: true,
          onMotionChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Updates for demo reports'));
    await tester.pump();
    store.ready.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.widgetWithText(
                SwitchListTile,
                'Updates for demo reports',
              ),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
  });
  testWidgets('settings load failure is shown', (tester) async {
    SharedPreferencesStorePlatform.instance = _ThrowingLoadStore();
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load settings.'), findsOneWidget);
  });

  testWidgets('clear removes contact even while restore is pending', (
    tester,
  ) async {
    final store = _DelayedStore({
      'flutter.reports_saved_contact_v1':
          '{"first":"Alex","last":"Doe","email":"a@example.com","phone":""}',
    });
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pump();
    store.ready.complete();
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'reports_saved_contact_v1',
      ),
      isNull,
    );
  });
  testWidgets('account preferences do not loop back to account', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(reduceMotion: false, onMotionChanged: (_) {}),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferences & accessibility'));
    await tester.pumpAndSettle();
    expect(find.text('Preferences'), findsWidgets);
    expect(find.text('Your account'), findsNothing);
    expect(find.text('Accessibility'), findsOneWidget);
  });
  testWidgets('directly opened account remains after profile save', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AccountPage(reduceMotion: false, onMotionChanged: (_) {}),
                ),
              ),
              child: const Text('Open account'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save demo profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
  });
  testWidgets('clearing waits for in-flight preference save', (tester) async {
    final store = _DelayedSetStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          reduceMotion: false,
          showDemoUpdates: true,
          onMotionChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Updates for demo reports'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Clear local preview data'), 200);
    await tester.ensureVisible(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local preview data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear preview data'));
    await tester.pump();
    store.ready.complete();
    await tester.pumpAndSettle();
    await (await SharedPreferences.getInstance()).reload();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'reports_demo_updates_v1',
      ),
      isNull,
    );
  });
  testWidgets('direct demo sign in returns to the service information page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const DemoSignInPage()),
              ),
              child: const Text('Service information'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Service information'));
    await tester.pumpAndSettle();
    await tester.enterText(accountField('Email'), 'a@example.com');
    await tester.enterText(accountField('Demo password'), 'demo');
    await tester.tap(find.text('Continue in demo'));
    await tester.pumpAndSettle();
    expect(find.text('Service information'), findsOneWidget);
    expect(
      find.text('Demo profile saved locally. No City account was changed.'),
      findsOneWidget,
    );
  });
}

class _FailingRemoveStore extends InMemorySharedPreferencesStore {
  _FailingRemoveStore(super.data) : super.withData();
  @override
  Future<bool> remove(String key) async => false;
}

class _FailingSetStore extends InMemorySharedPreferencesStore {
  _FailingSetStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _ThrowingSetStore extends InMemorySharedPreferencesStore {
  _ThrowingSetStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw StateError('failed');
}

class _DelayedStore extends InMemorySharedPreferencesStore {
  _DelayedStore(super.data) : super.withData();
  final ready = Completer<void>();
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    await ready.future;
    return super.getAllWithParameters(parameters);
  }
}

class _ThrowingLoadStore extends InMemorySharedPreferencesStore {
  _ThrowingLoadStore() : super.empty();
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async => throw StateError('failed');
}

class _FailingProfileRemoveStore extends InMemorySharedPreferencesStore {
  _FailingProfileRemoveStore() : super.empty();
  @override
  Future<bool> remove(String key) async {
    if (key.endsWith('reports_local_profile_v1')) return false;
    return super.remove(key);
  }
}

class _DelayedSetStore extends InMemorySharedPreferencesStore {
  _DelayedSetStore() : super.empty();
  final ready = Completer<void>();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    await ready.future;
    return super.setValue(valueType, key, value);
  }
}
