import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/report/domain/report.dart';

void main() {
  test(
    'legacy review drafts migrate while new Contact drafts stay on Contact',
    () {
      final legacy = ReportDraft(createdAt: DateTime(2026), step: 4).toJson();
      legacy.remove('flowVersion');
      expect(ReportDraft.fromJson(legacy).step, 5);
      final current = ReportDraft(
        createdAt: DateTime(2026),
        step: 4,
        flowVersion: 2,
      );
      expect(ReportDraft.fromJson(current.toJson()).step, 4);
    },
  );

  test('contact details survive draft, report and accepted receipt', () {
    const contact = ReportContact(
      anonymous: false,
      firstName: 'Ada',
      lastName: 'Jones',
      email: 'ada@example.com',
      phone: '5551234567',
    );
    final draft = ReportDraft(createdAt: DateTime(2026), contact: contact);
    final restored = ReportDraft.fromJson(draft.toJson()).contact!;
    expect(
      [
        restored.anonymous,
        restored.firstName,
        restored.lastName,
        restored.email,
        restored.phone,
      ],
      [false, 'Ada', 'Jones', 'ada@example.com', '5551234567'],
    );
    final report = Report(
      description: 'Items',
      latitude: 34,
      longitude: -118,
      createdAt: DateTime(2026),
      contact: contact,
    );
    final accepted = Report.fromJson(report.submittedWith('C-123').toJson());
    expect(accepted.serviceRequestNumber, 'C-123');
    expect(accepted.contact!.email, 'ada@example.com');
  });
}
