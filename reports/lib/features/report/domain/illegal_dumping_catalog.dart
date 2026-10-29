import 'dart:convert';

import 'package:flutter/services.dart';
import 'report_item.dart';

class ItemDefinition {
  const ItemDefinition({
    required this.name,
    required this.locationField,
    required this.quantityField,
  });
  final String name;
  final String locationField;
  final String quantityField;

  factory ItemDefinition.fromJson(Map<String, dynamic> json) => ItemDefinition(
    name: json['name'] as String,
    locationField: json['locationField'] as String,
    quantityField: json['quantityField'] as String,
  );
}

class ItemFamily {
  ItemFamily({
    required this.name,
    required this.selectionField,
    required List<ItemDefinition> items,
  }) : items = List.unmodifiable(items);
  final String name;
  final String selectionField;
  final List<ItemDefinition> items;

  factory ItemFamily.fromJson(Map<String, dynamic> json) => ItemFamily(
    name: json['name'] as String,
    selectionField: json['selectionField'] as String,
    items: (json['items'] as List)
        .map((item) => ItemDefinition.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class IllegalDumpingCatalog {
  IllegalDumpingCatalog({required List<ItemFamily> families})
    : families = List.unmodifiable(families);
  final List<ItemFamily> families;

  static Future<IllegalDumpingCatalog> load() async =>
      IllegalDumpingCatalog.fromJson(
        jsonDecode(
              await rootBundle.loadString('assets/illegal_dumping_items.json'),
            )
            as Map<String, dynamic>,
      );

  factory IllegalDumpingCatalog.fromJson(Map<String, dynamic> json) =>
      IllegalDumpingCatalog(
        families: (json['families'] as List)
            .map(
              (family) => ItemFamily.fromJson(family as Map<String, dynamic>),
            )
            .toList(),
      );

  static const locations = <String>{
    'Alley',
    'Center Median',
    'Cul-de-Sac',
    'Curb',
    'Dead End',
    'Easement/Pedestrian Walk',
    'On Bridge',
    'Side Street',
    'Stairway',
    'Under Bridge',
    'Under Freeway',
  };

  bool validSelection(String family, List<ReportItem> items) {
    if (items.isEmpty) return false;
    final seen = <String>{};
    return items.every((item) {
      final quantity = int.tryParse(item.quantity);
      return seen.add(item.name) &&
          contains(family, item.name) &&
          RegExp(r'^\d+$').hasMatch(item.quantity) &&
          quantity != null &&
          quantity >= 1 &&
          quantity <= 999 &&
          locations.contains(item.location);
    });
  }

  bool contains(String family, String name) => families.any(
    (group) =>
        group.name == family && group.items.any((item) => item.name == name),
  );
}
