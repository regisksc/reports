import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ServicePreviewStore {
  const ServicePreviewStore();

  static Future<void>? _pending;
  static List<Map<String, dynamic>> _session = [];
  static bool _unavailable = false;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    final previous = _pending;
    final gate = Completer<void>();
    _pending = gate.future;
    () async {
      if (previous != null) await previous;
      try {
        final value = await operation();
        if (identical(_pending, gate.future)) _pending = null;
        gate.complete();
        result.complete(value);
      } catch (error, stack) {
        if (identical(_pending, gate.future)) _pending = null;
        gate.complete();
        result.completeError(error, stack);
      }
    }();
    return result.future;
  }

  Future<List<Map<String, dynamic>>> _read() async {
    if (_unavailable) return List.of(_session);
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('service_previews_v1');
      final rows = value == null
          ? <Map<String, dynamic>>[]
          : (jsonDecode(value) as List)
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
      if (rows.any(
        (row) =>
            row['id'] is! String ||
            row['service'] is! String ||
            row['step'] is! int ||
            (row['step'] as int) < 0 ||
            (row['step'] as int) > 5 ||
            ((row['step'] as int) < 5 &&
                (row['group'] is! String || row['evidence'] is! String)) ||
            [
              'description',
              'address',
              'firstName',
              'lastName',
              'email',
              'phone',
            ].any((key) => row[key] != null && row[key] is! String) ||
            [
              'confirmed',
              'named',
              'following',
            ].any((key) => row[key] != null && row[key] is! bool) ||
            (row['photos'] != null &&
                (row['photos'] is! int || (row['photos'] as int) < 0)),
      )) {
        throw const FormatException('Invalid preview record');
      }
      _session = rows;
    } catch (_) {
      _unavailable = true;
    }
    return List.of(_session);
  }

  Future<bool> _write(
    List<Map<String, dynamic>> records, {
    bool clear = false,
  }) async {
    _session = records;
    if (_unavailable && !clear) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        'service_previews_v1',
        jsonEncode(records),
      );
      _unavailable = !saved;
      return saved;
    } catch (_) {
      _unavailable = true;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> load() => _enqueue(_read);

  Future<bool> save(Map<String, dynamic> record) => _enqueue(() async {
    final records = await _read();
    records.removeWhere((item) => item['id'] == record['id']);
    records.insert(0, Map.of(record));
    return _write(records);
  });

  Future<bool> remove(String id) => _enqueue(() async {
    final records = await _read();
    records.removeWhere((item) => item['id'] == id);
    return _write(records);
  });

  Future<bool> clear() => _enqueue(() async => _write([], clear: true));
}
