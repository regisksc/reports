import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/report_contact.dart';

class RememberedContactStore {
  const RememberedContactStore();

  static const storageKey = 'reports_saved_contact_v1';

  Future<ReportContact?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(storageKey);
    if (saved == null) return null;
    try {
      return ReportContact.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(ReportContact contact) async {
    if (contact.anonymous) throw ArgumentError('A named contact is required');
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      storageKey,
      jsonEncode({
        'first': contact.firstName,
        'last': contact.lastName,
        'email': contact.email,
        'phone': contact.phone,
      }),
    );
    if (!saved) throw StateError('Contact could not be saved');
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(storageKey)) {
      throw StateError('Contact could not be forgotten');
    }
  }
}
