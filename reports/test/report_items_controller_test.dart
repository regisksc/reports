import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:reports/features/report/application/report_flow_controller.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/domain/submission_contract.dart';

import 'support/native_app_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected items require a known family, locations and quantities',
    () async {
      final store = MemoryReportStore();
      final controller = ReportFlowController(
        store: store,
        client: NoSubmissionClient(),
      );
      await controller.checkSavedAttempts();
      await controller.loadItemCatalog();
      controller.step = 1;
      controller.updateItems('Bulky Items', []);
      expect(controller.canContinue, isFalse);
      controller.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Bed Frame (Wood)',
          quantity: '0',
          location: 'Curb',
        ),
      ]);
      expect(controller.canContinue, isFalse);
      controller.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Bed Frame (Wood)',
          quantity: '2',
          location: 'Curb',
        ),
      ]);
      expect(controller.canContinue, isTrue);
      await controller.persistDraft();
      expect(store.draft!.itemFamily, 'Bulky Items');
      expect(store.draft!.items.single.name, 'Bed Frame (Wood)');
      controller.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Not a City option',
          quantity: '2',
          location: 'Curb',
        ),
      ]);
      expect(controller.canContinue, isFalse);
      controller.dispose();
    },
  );
  test(
    'item data without a family cannot fall back to legacy submission',
    () async {
      final draft = ReportDraft(
        createdAt: DateTime(2026),
        latitude: 34,
        longitude: -118,
        debrisLocation: 'Curb',
        quantity: '1',
        items: [
          const ReportItem(
            name: 'Bed Frame (Wood)',
            quantity: '1',
            location: 'Curb',
          ),
        ],
      );
      final controller = ReportFlowController(
        store: MemoryReportStore(),
        client: NoSubmissionClient(),
        draft: draft,
      );
      await controller.checkSavedAttempts();
      controller.step = 1;
      expect(controller.canContinue, isFalse);
      controller.dispose();
    },
  );
  test('rapid item edits cannot overwrite a newer draft', () async {
    final store = _DelayedDraftStore();
    final controller = ReportFlowController(
      store: store,
      client: NoSubmissionClient(),
    );
    await controller.checkSavedAttempts();
    controller.updateItems('Bulky Items', [
      const ReportItem(name: 'Basketball Set', quantity: '1', location: 'Curb'),
    ]);
    await store.started.future;
    controller.updateItems('Bulky Items', [
      const ReportItem(
        name: 'Bed Frame (Wood)',
        quantity: '2',
        location: 'Alley',
      ),
    ]);
    await Future<void>.value();
    store.release.complete();
    await store.firstDone.future;
    await store.secondDone.future;
    expect(store.draft!.items.single.name, 'Bed Frame (Wood)');
    controller.dispose();
  });
  test(
    'item choices survive accepted and rejected submission records',
    () async {
      for (final result in [
        SubmissionAccepted('C-TEST'),
        SubmissionFailed(SubmissionFailureKind.rejected, 'Rejected'),
      ]) {
        final store = MemoryReportStore();
        final controller = ReportFlowController(
          store: store,
          client: _ResultClient(result),
        );
        await controller.checkSavedAttempts();
        await controller.loadItemCatalog();
        controller.position = (latitude: 34, longitude: -118);
        controller.contact = const ReportContact(anonymous: true);
        controller.updateItems('Bulky Items', [
          const ReportItem(
            name: 'Bed Frame (Wood)',
            quantity: '2',
            location: 'Curb',
          ),
        ]);
        await controller.submit();
        final retained = store.reports.single;
        expect(retained.itemFamily, 'Bulky Items');
        expect(retained.items.single.name, 'Bed Frame (Wood)');
        expect(retained.items.single.quantity, '2');
        expect(retained.items.single.location, 'Curb');
        controller.dispose();
      }
    },
  );
  test('unavailable item catalog fails closed with an explanation', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (_) async => null);
    rootBundle.clear();
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.clear();
    });
    final controller = ReportFlowController(
      store: MemoryReportStore(),
      client: NoSubmissionClient(),
    );
    await controller.checkSavedAttempts();
    await controller.loadItemCatalog();
    expect(controller.itemCatalog, isNull);
    expect(controller.itemCatalogError, 'Item choices could not be loaded.');
    controller.updateItems('Bulky Items', [
      const ReportItem(
        name: 'Bed Frame (Wood)',
        quantity: '1',
        location: 'Curb',
      ),
    ]);
    controller.step = 1;
    expect(controller.canContinue, isFalse);
    controller.dispose();
  });
  test(
    'submission waits for pending draft writes before a new report starts',
    () async {
      final store = _DelayedDraftStore();
      final client = _CountingClient();
      final old = ReportFlowController(store: store, client: client);
      await old.checkSavedAttempts();
      await old.loadItemCatalog();
      old.position = (latitude: 34, longitude: -118);
      old.contact = const ReportContact(anonymous: true);
      old.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Bed Frame (Wood)',
          quantity: '2',
          location: 'Curb',
        ),
      ]);
      await store.started.future;
      final submission = old.submit();
      await Future<void>.value();
      expect(client.calls, 0);
      store.release.complete();
      await submission;
      expect(client.calls, 1);
      final newer = ReportFlowController(
        store: store,
        client: NoSubmissionClient(),
      );
      await newer.checkSavedAttempts();
      newer.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Basketball Set',
          quantity: '1',
          location: 'Alley',
        ),
      ]);
      await newer.flushDraftWrites();
      expect(store.draft!.items.single.name, 'Basketball Set');
      old.dispose();
      newer.dispose();
    },
  );
  test(
    'disposing while waiting for draft storage prevents submission',
    () async {
      final store = _DelayedDraftStore();
      final client = _CountingClient();
      final controller = ReportFlowController(store: store, client: client);
      await controller.checkSavedAttempts();
      await controller.loadItemCatalog();
      controller.position = (latitude: 34, longitude: -118);
      controller.contact = const ReportContact(anonymous: true);
      controller.updateItems('Bulky Items', [
        const ReportItem(
          name: 'Bed Frame (Wood)',
          quantity: '2',
          location: 'Curb',
        ),
      ]);
      await store.started.future;
      final submission = controller.submit();
      controller.dispose();
      store.release.complete();
      await submission;
      expect(client.calls, 0);
      expect(store.reports, isEmpty);
    },
  );
  test('fresh report requires an explicit item selection', () async {
    final store = MemoryReportStore();
    final controller = ReportFlowController(
      store: store,
      client: NoSubmissionClient(),
    );
    await controller.checkSavedAttempts();
    await controller.loadItemCatalog();
    controller.position = (latitude: 34, longitude: -118);
    controller.debris = 'Curb';
    controller.quantityText = '1';
    controller.step = 1;
    expect(controller.itemFamily, "I'm not sure");
    expect(controller.items, isEmpty);
    expect(controller.canContinue, isFalse);
    await controller.persistDraft();
    expect(store.draft!.itemFamily, "I'm not sure");
    expect(store.draft!.items, isEmpty);
    controller.dispose();
  });
  test('pending draft state is observable until all writes finish', () async {
    final store = _DelayedDraftStore();
    final controller = ReportFlowController(
      store: store,
      client: NoSubmissionClient(),
    );
    await controller.checkSavedAttempts();
    final states = <bool>[];
    controller.addListener(() => states.add(controller.hasPendingDraftWrites));
    controller.updateItems('Bulky Items', [
      const ReportItem(name: 'Basketball Set', quantity: '1', location: 'Curb'),
    ]);
    await store.started.future;
    controller.updateItems('Bulky Items', [
      const ReportItem(
        name: 'Bed Frame (Wood)',
        quantity: '2',
        location: 'Curb',
      ),
    ]);
    expect(controller.hasPendingDraftWrites, isTrue);
    store.release.complete();
    await controller.flushDraftWrites();
    expect(controller.hasPendingDraftWrites, isFalse);
    expect(states, containsAllInOrder([true, false]));
    controller.dispose();
  });
}

class _DelayedDraftStore extends MemoryReportStore {
  final started = Completer<void>();
  final release = Completer<void>();
  final firstDone = Completer<void>();
  final secondDone = Completer<void>();
  int calls = 0;
  @override
  Future<void> saveDraft(ReportDraft value) async {
    if (calls++ == 0) {
      started.complete();
      await release.future;
      await super.saveDraft(value);
      firstDone.complete();
      return;
    }
    await super.saveDraft(value);
    if (!secondDone.isCompleted) secondDone.complete();
  }
}

class _ResultClient implements SubmissionClient {
  _ResultClient(this.result);
  final SubmissionResult result;
  @override
  Future<SubmissionResult> send(Report report) async => result;
}

class _CountingClient implements SubmissionClient {
  int calls = 0;
  @override
  Future<SubmissionResult> send(Report report) async {
    calls++;
    return SubmissionAccepted('C-TEST');
  }
}
