import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/data/local_report_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const testStore = LocalReportStore();

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform originalPaths;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    supportDirectory = await Directory.systemTemp.createTemp(
      'reports-storage-',
    );
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await supportDirectory.delete(recursive: true);
  });

  test(
    'local removal preserves uncertain markers and stale actions cannot clear them',
    () async {
      final attempt = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });
      await testStore.saveReport(attempt);
      await testStore.saveDraft(
        ReportDraft(
          createdAt: attempt.createdAt,
          description: attempt.description,
          latitude: attempt.latitude,
          longitude: attempt.longitude,
          quantity: '3',
          debrisLocation: 'Curb',
          step: 4,
        ),
      );
      final outcomes = <String, Object?>{};
      outcomes['discard'] = await testStore
          .discardDraft(attempt.createdAt)
          .then(
            (_) => 'removed',
            onError: (Object error) => error is StateError
                ? 'StateError'
                : error is FileSystemException
                ? 'FileSystemException'
                : throw error,
          );
      outcomes['receipt'] = await testStore
          .removeLocalReceipt(attempt)
          .then(
            (_) => 'removed',
            onError: (Object error) => error is StateError
                ? 'StateError'
                : error is FileSystemException
                ? 'FileSystemException'
                : throw error,
          );
      PathProviderPlatform.instance = _UnavailableSupportPath();
      outcomes['cleanup'] = await testStore
          .replaceReport(attempt, attempt.submittedWith('SR-SYNTHETIC-REMOVE'))
          .then(
            (_) => 'saved',
            onError: (Object error) => error is StateError
                ? 'StateError'
                : error is FileSystemException
                ? 'FileSystemException'
                : throw error,
          );
      PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
      await testStore.removeLocalReceipt(
        (await testStore.loadReports()).single,
      );
      outcomes['marker'] = File(
        '${supportDirectory.path}/submission-attempt.json',
      ).existsSync();
      outcomes['reports'] = (await testStore.loadReports())
          .map((report) => report.toJson())
          .toList();
      outcomes['resend'] = await testStore
          .saveReport(attempt)
          .then(
            (_) => 'saved',
            onError: (Object error) => error is StateError
                ? 'StateError'
                : error is FileSystemException
                ? 'FileSystemException'
                : throw error,
          );
      expect(outcomes, {
        'discard': 'StateError',
        'receipt': 'StateError',
        'cleanup': 'FileSystemException',
        'marker': true,
        'reports': [attempt.toJson()],
        'resend': 'FileSystemException',
      });
    },
  );

  test(
    'a saved Report keeps its details as not sent without a receipt',
    () async {
      await testStore.saveReport(
        Report(
          description: 'Couch on sidewalk',
          latitude: 34.05,
          longitude: -118.24,
          createdAt: DateTime(2026, 10, 1, 9),
        ),
      );

      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {
          'description': 'Couch on sidewalk',
          'latitude': 34.05,
          'longitude': -118.24,
          'createdAt': '2026-10-01T09:00:00.000',
          'photoPath': null,
          'debrisLocation': null,
          'quantity': null,
          'state': 'notSent',
          'serviceRequestNumber': null,
        },
      ]);
    },
  );

  test('testStore.loadReports skips old-version and malformed rows', () async {
    SharedPreferences.setMockInitialValues({
      'reports_v1': [jsonEncode(_fields)],
      'reports_v2': [
        jsonEncode(_fields),
        'not json',
        '{"description": 1}',
        jsonEncode({..._fields, 'state': 'bogus'}),
      ],
    });

    final loaded = await testStore.loadReports();

    expect(loaded.map((report) => report.toJson()).toList(), [_fields]);
  });

  test(
    'a receipt replaces the saved draft while preserving newest-first order',
    () async {
      final draft = Report.fromJson(_fields);
      await testStore.saveReport(draft);
      await testStore.saveReport(
        Report.fromJson({
          ..._fields,
          'description': 'Tires in alley',
          'createdAt': '2026-10-01T10:00:00.000',
        }),
      );

      await testStore.replaceReport(draft, draft.submittedWith('SR-7'));
      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {
          ..._fields,
          'description': 'Tires in alley',
          'createdAt': '2026-10-01T10:00:00.000',
        },
        {..._fields, 'state': 'submitted', 'serviceRequestNumber': 'SR-7'},
      ]);
    },
  );

  test('a receipt is retained when the original draft row is absent', () async {
    final draft = Report.fromJson(_fields);

    await testStore.replaceReport(draft, draft.submittedWith('SR-8'));
    final loaded = await testStore.loadReports();

    expect(loaded.map((report) => report.toJson()).toList(), [
      {..._fields, 'state': 'submitted', 'serviceRequestNumber': 'SR-8'},
    ]);
  });

  test(
    'an unconfirmed submission keeps its details across storage reload',
    () async {
      final report = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });

      await testStore.saveReport(report);
      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {..._fields, 'state': 'submissionUncertain'},
      ]);
    },
  );

  for (final operation in ['save', 'replace']) {
    test('an unconfirmed $operation survives lost preference data', () async {
      final attempt = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });
      if (operation == 'save') {
        await testStore.saveReport(attempt);
      } else {
        final draft = Report.fromJson(_fields);
        await testStore.saveReport(draft);
        await testStore.replaceReport(draft, attempt);
      }
      SharedPreferences.setMockInitialValues({});

      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {..._fields, 'state': 'submissionUncertain'},
      ]);
    });
  }

  for (final marker in [
    'not json',
    jsonEncode({..._fields, 'state': 'submitted'}),
  ]) {
    test('an invalid attempt marker blocks report loading: $marker', () async {
      await testStore.saveReport(
        Report.fromJson({..._fields, 'state': 'submissionUncertain'}),
      );
      final file = await supportDirectory
          .list()
          .where((entry) => entry is File)
          .cast<File>()
          .single;
      await file.writeAsString(marker, flush: true);
      SharedPreferences.setMockInitialValues({});

      await expectLater(
        testStore.loadReports(),
        throwsA(isA<FormatException>()),
      );
    });
  }

  for (final state in ['notSent', 'submitted']) {
    test('a confirmed $state result releases its attempt marker', () async {
      final attempt = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });
      await testStore.saveReport(attempt);
      final result = Report.fromJson({
        ..._fields,
        'state': state,
        'serviceRequestNumber': state == 'submitted' ? 'SR-9' : null,
      });
      await testStore.replaceReport(attempt, result);
      final nextAttempt = Report.fromJson({
        ..._fields,
        'description': 'Tires in alley',
        'createdAt': '2026-10-01T10:00:00.000',
        'state': 'submissionUncertain',
      });

      await testStore.saveReport(nextAttempt);
      SharedPreferences.setMockInitialValues({});
      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {
          ..._fields,
          'description': 'Tires in alley',
          'createdAt': '2026-10-01T10:00:00.000',
          'state': 'submissionUncertain',
        },
      ]);
    });
  }

  for (final operation in ['save', 'replace']) {
    test('a failed preference $operation reports a storage failure', () async {
      SharedPreferencesStorePlatform.instance = _FailingStore();
      final draft = Report.fromJson(_fields);

      final write = operation == 'save'
          ? testStore.saveReport(draft)
          : testStore.replaceReport(draft, draft.submittedWith('SR-9'));

      await expectLater(write, throwsA(isA<StateError>()));
    });
  }

  test(
    'a failed receipt write keeps the unconfirmed attempt recoverable',
    () async {
      final attempt = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });
      await testStore.saveReport(attempt);
      SharedPreferencesStorePlatform.instance = _FailingStore();

      final outcome = await testStore
          .replaceReport(attempt, attempt.submittedWith('SR-9'))
          .then(
            (_) => 'saved',
            onError: (Object error) =>
                error is StateError ? 'failed' : throw error,
          );
      SharedPreferences.setMockInitialValues({});
      final loaded = await testStore.loadReports();

      expect(
        {
          'outcome': outcome,
          'reports': loaded.map((report) => report.toJson()).toList(),
        },
        {
          'outcome': 'failed',
          'reports': [
            {..._fields, 'state': 'submissionUncertain'},
          ],
        },
      );
    },
  );

  test(
    'a receipt survives failed attempt cleanup and keeps sends blocked',
    () async {
      final attempt = Report.fromJson({
        ..._fields,
        'state': 'submissionUncertain',
      });
      await testStore.saveReport(attempt);
      PathProviderPlatform.instance = _UnavailableSupportPath();

      await expectLater(
        testStore.replaceReport(attempt, attempt.submittedWith('SR-10')),
        throwsA(isA<FileSystemException>()),
      );
      PathProviderPlatform.instance = _SupportPath(supportDirectory.path);
      final loaded = await testStore.loadReports();

      expect(loaded.map((report) => report.toJson()).toList(), [
        {..._fields, 'state': 'submitted', 'serviceRequestNumber': 'SR-10'},
      ]);
      await expectLater(
        testStore.saveReport(attempt),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}

class _UnavailableSupportPath extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw const FileSystemException('Support directory unavailable');
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _SupportPath extends PathProviderPlatform {
  _SupportPath(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

const _fields = {
  'description': 'Couch on sidewalk',
  'latitude': 34.05,
  'longitude': -118.24,
  'createdAt': '2026-10-01T09:00:00.000',
  'photoPath': '/photos/couch.jpg',
  'debrisLocation': 'Curb',
  'quantity': 3,
  'state': 'notSent',
  'serviceRequestNumber': null,
};
