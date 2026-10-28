import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/data/remembered_contact_store.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('contact values survive serialization', () {
    const contact = ReportContact(
      anonymous: false,
      firstName: 'Ada',
      lastName: 'Jones',
      email: 'ada@example.com',
      phone: '555',
    );
    final copy = ReportContact.fromJson(contact.toJson());
    expect(
      [copy.anonymous, copy.firstName, copy.lastName, copy.email, copy.phone],
      [false, 'Ada', 'Jones', 'ada@example.com', '555'],
    );
    final empty = ReportContact.fromJson({});
    expect(
      [
        empty.anonymous,
        empty.firstName,
        empty.lastName,
        empty.email,
        empty.phone,
      ],
      [false, '', '', '', ''],
    );
  });
  test('remembered contact can be reused and forgotten', () async {
    SharedPreferences.setMockInitialValues({});
    const store = RememberedContactStore();
    expect(await store.load(), isNull);
    await store.save(
      const ReportContact(
        anonymous: false,
        firstName: 'Ada',
        lastName: 'Jones',
        email: 'ada@example.com',
        phone: '555',
      ),
    );
    final saved = await store.load();
    expect(
      [saved!.firstName, saved.lastName, saved.email, saved.phone],
      ['Ada', 'Jones', 'ada@example.com', '555'],
    );
    await store.clear();
    expect(await store.load(), isNull);
  });

  test(
    'invalid data and storage failure are handled without claiming success',
    () async {
      const store = RememberedContactStore();
      SharedPreferences.setMockInitialValues({
        RememberedContactStore.storageKey: '{',
      });
      expect(await store.load(), isNull);
      SharedPreferences.setMockInitialValues({
        RememberedContactStore.storageKey: '[]',
      });
      expect(await store.load(), isNull);
      await expectLater(
        store.save(const ReportContact(anonymous: true)),
        throwsArgumentError,
      );
      SharedPreferencesStorePlatform.instance = _FailingStore();
      SharedPreferences.resetStatic();
      await expectLater(
        store.save(const ReportContact(anonymous: false)),
        throwsStateError,
      );
      await expectLater(store.clear(), throwsStateError);
      SharedPreferences.setMockInitialValues({});
    },
  );
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
  @override
  Future<bool> remove(String key) async => false;
}
