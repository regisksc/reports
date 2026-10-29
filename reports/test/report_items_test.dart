import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/domain/illegal_dumping_catalog.dart';
import 'package:reports/features/report/domain/report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('selected items survive draft, report, and receipt serialization', () {
    const item = ReportItem(name: 'Couch', quantity: '2', location: 'Curb');
    final draft = ReportDraft(
      createdAt: DateTime(2026),
      itemFamily: 'Bulky Items',
      items: [item],
    );
    final restored = ReportDraft.fromJson(draft.toJson());
    expect(restored.itemFamily, 'Bulky Items');
    expect(restored.items.single.name, 'Couch');
    expect(restored.items.single.quantity, '2');
    expect(restored.items.single.location, 'Curb');
    final report = Report(
      description: '',
      latitude: 34,
      longitude: -118,
      createdAt: DateTime(2026),
      itemFamily: restored.itemFamily,
      items: restored.items,
    );
    final receipt = Report.fromJson(report.submittedWith('C-TEST').toJson());
    expect(receipt.itemFamily, 'Bulky Items');
    expect(receipt.items.single.name, 'Couch');
    expect(receipt.serviceRequestNumber, 'C-TEST');
  });
  test('legacy records preserve their original shape and values', () {
    final old = ReportDraft(
      createdAt: DateTime(2026),
      debrisLocation: 'Curb',
      quantity: '2',
    );
    final json = old.toJson();
    expect(json.containsKey('items'), isFalse);
    expect(json.containsKey('itemFamily'), isFalse);
    final restored = ReportDraft.fromJson(json);
    expect(restored.items, isEmpty);
    expect(restored.itemFamily, isNull);
    expect(restored.debrisLocation, 'Curb');
    expect(restored.quantity, '2');
  });

  test('draft selections are an immutable snapshot', () {
    final items = [
      const ReportItem(name: 'Couch', quantity: '2', location: 'Curb'),
    ];
    final draft = ReportDraft(
      createdAt: DateTime(2026),
      itemFamily: 'Bulky Items',
      items: items,
    );
    items.clear();
    expect(draft.items, hasLength(1));
    expect(() => draft.items.clear(), throwsUnsupportedError);
  });
  test('verified catalog resolves irregular City question fields', () async {
    final catalog = await IllegalDumpingCatalog.load();
    final family = catalog.families.singleWhere(
      (family) => family.name == 'Bulky Items',
    );
    final item = family.items.singleWhere(
      (item) => item.name == 'Bed Frame (Wood)',
    );
    expect(family.selectionField, 'Illegally_Dumped_Other_Item_Options__c');
    expect(item.locationField, 'Location_of_Bed_Frame_Wood__c');
    expect(item.quantityField, 'No_of_Bedframe_Wood__c');
    expect(catalog.contains('Bulky Items', 'Not a City option'), isFalse);
  });
  test(
    'item validation enforces known options and quantity boundaries',
    () async {
      final catalog = await IllegalDumpingCatalog.load();
      ReportItem item(
        String quantity,
        String? location, {
        String name = 'Bed Frame (Wood)',
      }) => ReportItem(name: name, quantity: quantity, location: location);
      expect(
        catalog.validSelection('Bulky Items', [item('1', 'Curb')]),
        isTrue,
      );
      expect(
        catalog.validSelection('Bulky Items', [item('999', 'Alley')]),
        isTrue,
      );
      for (final quantity in ['', '0', '1000', '-1', '1.5']) {
        expect(
          catalog.validSelection('Bulky Items', [item(quantity, 'Curb')]),
          isFalse,
        );
      }
      expect(catalog.validSelection('Bulky Items', [item('1', null)]), isFalse);
      expect(
        catalog.validSelection('Bulky Items', [item('1', 'Inside')]),
        isFalse,
      );
      expect(
        catalog.validSelection('Electronic Waste', [item('1', 'Curb')]),
        isFalse,
      );
      expect(
        catalog.validSelection('Bulky Items', [
          item('1', 'Curb'),
          item('2', 'Alley'),
        ]),
        isFalse,
      );
      expect(catalog.validSelection('Bulky Items', []), isFalse);
    },
  );

  test('explicitly empty selection remains distinct from a legacy draft', () {
    final draft = ReportDraft(
      createdAt: DateTime(2026),
      itemFamily: 'Bulky Items',
    );
    final restored = ReportDraft.fromJson(draft.toJson());
    expect(restored.itemFamily, 'Bulky Items');
    expect(restored.items, isEmpty);
  });
}
