import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/application/report_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  testWidgets('Contact requires a choice and named details before Review', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            description: 'Couch',
            debrisLocation: 'Curb',
            quantity: '1',
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 6 · Contact'), findsOneWidget);
    expect(
      find.text(
        'Your draft stays on this device. If you include contact details, they are sent to the City with your report.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.widgetWithText(TextField, 'First name'), 'Ada');
    await tester.enterText(
      find.widgetWithText(TextField, 'Last name'),
      'Jones',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'a@',
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'ada@example.com',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 6 of 6 · Review'), findsOneWidget);
    expect(find.textContaining('Ada Jones'), findsOneWidget);
  });
  testWidgets('remembered details prefill a draft without a contact choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'reports_saved_contact_v1':
          '{"first":"Ada","last":"Jones","email":"ada@example.com","phone":"555"}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      true,
    );
  });

  testWidgets('remembering and forgetting affects future reports', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'reports_saved_contact_v1':
          '{"first":"Ada","last":"Jones","email":"ada@example.com","phone":"555"}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            description: 'Couch',
            debrisLocation: 'Curb',
            quantity: '1',
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'reports_saved_contact_v1',
      ),
      isNull,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'reports_saved_contact_v1',
      ),
      contains('ada@example.com'),
    );
    expect(find.text('Step 6 of 6 · Review'), findsOneWidget);
  });

  testWidgets(
    'anonymous choice excludes remembered personal details from the draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'reports_saved_contact_v1':
            '{"first":"Ada","last":"Jones","email":"ada@example.com","phone":"555"}',
      });
      final store = _MemoryStore();
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFlowPage(
            store: store,
            client: _NoSubmission(),
            draft: ReportDraft(
              createdAt: DateTime(2026),
              latitude: 34,
              longitude: -118,
              step: 4,
              flowVersion: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Without contact details'));
      await tester.pumpAndSettle();
      final contact = store.draft!.contact!;
      expect(contact.anonymous, true);
      expect(
        [contact.firstName, contact.lastName, contact.email, contact.phone],
        ['', '', '', ''],
      );
      await tester.tap(find.text('Include my contact details'));
      await tester.pumpAndSettle();
      expect(find.text('Ada'), findsOneWidget);
    },
  );

  testWidgets('Contact remains usable at 320 pixels with doubled text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Include my contact details'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remembered contact failures are visible and do not advance', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = _FailingPreferences();
    SharedPreferences.resetStatic();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            description: 'Couch',
            debrisLocation: 'Curb',
            quantity: '1',
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include my contact details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('could not be saved for reuse'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('could not be saved for reuse'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be forgotten'), findsOneWidget);
  });

  testWidgets('saved contact load failure is visible', (tester) async {
    SharedPreferencesStorePlatform.instance = _UnavailablePreferences();
    SharedPreferences.resetStatic();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _MemoryStore(),
          client: _NoSubmission(),
          draft: ReportDraft(
            createdAt: DateTime(2026),
            latitude: 34,
            longitude: -118,
            step: 4,
            flowVersion: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('could not be loaded'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('could not be loaded'), findsOneWidget);
  });

  testWidgets('Back waits for pending draft saves before leaving', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedDraftStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: DateTime(2026),
                      latitude: 34,
                      longitude: -118,
                      step: 1,
                      flowVersion: 2,
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await store.started.future;
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.text('New report'), findsOneWidget);
    expect(find.text('Open report'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
    store.release.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
  });

  testWidgets('Save and close disables Submit while a draft is being saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedDraftStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: DateTime(2026),
                      latitude: 34,
                      longitude: -118,
                      step: 5,
                      flowVersion: 2,
                      debrisLocation: 'Curb',
                      quantity: '1',
                      contact: const ReportContact(anonymous: true),
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save and close'));
    await tester.pump();
    await store.started.future;
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'))
          .onPressed,
      isNull,
    );
    store.release.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
  });

  testWidgets('a pending contact save cannot advance after exit starts', (
    tester,
  ) async {
    final preferences = _DelayedContactPreferences();
    SharedPreferencesStorePlatform.instance = preferences;
    SharedPreferences.resetStatic();
    final store = _DelayedDraftStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: DateTime(2026),
                      latitude: 34,
                      longitude: -118,
                      step: 4,
                      flowVersion: 2,
                      contact: const ReportContact(
                        anonymous: false,
                        firstName: 'Ada',
                        lastName: 'Jones',
                        email: 'ada@example.com',
                      ),
                      rememberContact: true,
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await preferences.started.future;
    await tester.tap(find.text('Save and close'));
    await tester.pump();
    await store.started.future;
    preferences.release.complete();
    await tester.pump();
    expect(find.text('Step 5 of 6 · Contact'), findsOneWidget);
    store.release.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
    SharedPreferences.setMockInitialValues({});
  });

  for (final discard in [false, true]) {
    testWidgets(
      discard
          ? 'Discard waits for pending saves'
          : 'System back waits for pending saves',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final store = _DelayedDraftStore();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReportFlowPage(
                        store: store,
                        client: _NoSubmission(),
                        draft: ReportDraft(
                          createdAt: DateTime(2026),
                          latitude: 34,
                          longitude: -118,
                          step: 1,
                          flowVersion: 2,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open report'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open report'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await store.started.future;
        if (discard) {
          await tester.tap(find.byTooltip('Discard draft'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Remove'));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pump();
        expect(find.text('New report'), findsOneWidget);
        expect(store.discarded, false);
        store.release.complete();
        await tester.pumpAndSettle();
        expect(find.text('Open report'), findsOneWidget);
        expect(store.discarded, discard);
      },
    );
  }

  testWidgets('failed discard leaves the form open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _FailingRemovalStore(),
          client: _NoSubmission(),
          draft: ReportDraft(createdAt: DateTime(2026)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Discard draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not remove this local record. Try again.'),
      findsOneWidget,
    );
    expect(find.text('New report'), findsOneWidget);
  });

  testWidgets('failed save and close keeps the form open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFlowPage(
          store: _FailingSaveStore(),
          client: _NoSubmission(),
          draft: ReportDraft(createdAt: DateTime(2026)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(find.text('New report'), findsOneWidget);
    expect(find.textContaining('Draft could not be saved'), findsOneWidget);
  });

  testWidgets('corrected Not sent report can save and close', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final original = Report(
      description: 'Original',
      latitude: 34,
      longitude: -118,
      createdAt: DateTime(2026),
      debrisLocation: 'Curb',
      quantity: 1,
    );
    final store = _NotSentStore(original);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: original.createdAt,
                      description: 'Correction',
                      latitude: 34,
                      longitude: -118,
                      debrisLocation: 'Curb',
                      quantity: '1',
                      step: 5,
                      flowVersion: 2,
                      contact: const ReportContact(anonymous: true),
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Discard draft'), findsNothing);
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
    expect(store.draft!.description, 'Correction');
    expect((await store.loadReports()).single.description, 'Original');
  });

  testWidgets('iOS back swipe waits until the draft queue is idle', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = _DelayedDraftStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: DateTime(2026),
                      latitude: 34,
                      longitude: -118,
                      step: 1,
                      flowVersion: 2,
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await store.started.future;
    await tester.dragFrom(const Offset(2, 300), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('New report'), findsOneWidget);
    store.release.complete();
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(2, 300), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
  });

  testWidgets('Save and close keeps the current draft', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _MemoryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReportFlowPage(
                    store: store,
                    client: _NoSubmission(),
                    draft: ReportDraft(
                      createdAt: DateTime(2026),
                      latitude: 34,
                      longitude: -118,
                      step: 4,
                      flowVersion: 2,
                    ),
                  ),
                ),
              ),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Without contact details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(find.text('Open report'), findsOneWidget);
    final draft = await store.loadDraft();
    expect(draft!.step, 4);
    expect(draft.contact!.anonymous, true);
  });
}

class _NoSubmission implements SubmissionClient {
  @override
  Future<SubmissionResult> send(Report report) =>
      throw StateError('No live submissions');
}

class _MemoryStore implements ReportStore {
  ReportDraft? draft;
  @override
  Future<ReportDraft?> loadDraft() async => draft;
  @override
  Future<void> saveDraft(ReportDraft value) async {
    draft = value;
  }

  @override
  Future<List<Report>> loadReports() async => [];
  @override
  Future<void> saveReport(Report report) async {}
  @override
  Future<void> replaceReport(Report before, Report after) async {}
  @override
  Future<void> discardDraft(DateTime createdAt) async {}
  @override
  Future<void> removeLocalReceipt(Report receipt) async {}
}

class _FailingPreferences extends InMemorySharedPreferencesStore {
  _FailingPreferences() : super.empty();
  @override
  Future<Map<String, Object>> getAll() async => {
    'flutter.reports_saved_contact_v1':
        '{"first":"Ada","last":"Jones","email":"ada@example.com","phone":"555"}',
  };
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
  @override
  Future<bool> remove(String key) async => false;
}

class _UnavailablePreferences extends InMemorySharedPreferencesStore {
  _UnavailablePreferences() : super.empty();
  @override
  Future<Map<String, Object>> getAll() async => throw StateError('unavailable');
}

class _DelayedContactPreferences extends InMemorySharedPreferencesStore {
  _DelayedContactPreferences() : super.empty();
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    started.complete();
    await release.future;
    return super.setValue(valueType, key, value);
  }
}

class _DelayedDraftStore extends _MemoryStore {
  final started = Completer<void>();
  final release = Completer<void>();
  bool discarded = false;
  @override
  Future<void> discardDraft(DateTime createdAt) async {
    discarded = true;
  }

  @override
  Future<void> saveDraft(ReportDraft value) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await super.saveDraft(value);
  }
}

class _FailingRemovalStore extends _MemoryStore {
  @override
  Future<void> discardDraft(DateTime createdAt) async =>
      throw StateError('unavailable');
}

class _FailingSaveStore extends _MemoryStore {
  @override
  Future<void> saveDraft(ReportDraft draft) async =>
      throw StateError('unavailable');
}

class _NotSentStore extends _MemoryStore {
  _NotSentStore(this.report);
  final Report report;
  @override
  Future<List<Report>> loadReports() async => [report];
}
