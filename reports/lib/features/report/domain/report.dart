import 'report_contact.dart';
import 'report_item.dart';

export 'report_contact.dart';
export 'report_item.dart';

enum ReportState { notSent, submitted, failed, submissionUncertain }

class ReportDraft {
  ReportDraft({
    required this.createdAt,
    this.description = '',
    this.latitude,
    this.longitude,
    String? photoPath,
    List<String>? photoPaths,
    this.debrisLocation,
    this.quantity = '',
    this.step = 0,
    this.flowVersion = 1,
    this.contact,
    this.rememberContact = false,
    this.itemFamily,
    List<ReportItem> items = const [],
  }) : photoPaths = List.unmodifiable(photoPaths ?? [?photoPath]),
       items = List.unmodifiable(items);

  final DateTime createdAt;
  final String description;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
  String? get photoPath => photoPaths.isEmpty ? null : photoPaths.first;
  final String? debrisLocation;
  final String quantity;
  final int step;
  final int flowVersion;
  final ReportContact? contact;
  final bool rememberContact;
  final String? itemFamily;
  final List<ReportItem> items;

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'photoPath': photoPath,
    if (photoPaths.length > 1) 'photoPaths': photoPaths,
    'debrisLocation': debrisLocation,
    'quantity': quantity,
    'step': step,
    'flowVersion': flowVersion,
    'rememberContact': rememberContact,
    if (contact != null) 'contact': contact!.toJson(),
    if (itemFamily != null) 'itemFamily': itemFamily,
    if (items.isNotEmpty) 'items': items.map((item) => item.toJson()).toList(),
  };

  factory ReportDraft.fromJson(Map<String, dynamic> json) => ReportDraft(
    createdAt: DateTime.parse(json['createdAt'] as String),
    description: json['description'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    photoPath: json['photoPath'] as String?,
    photoPaths: (json['photoPaths'] as List?)?.cast<String>(),
    debrisLocation: json['debrisLocation'] as String?,
    quantity: json['quantity'] as String,
    step: (json['flowVersion'] as int? ?? 1) < 2 && json['step'] == 4
        ? 5
        : json['step'] as int,
    flowVersion: 2,
    rememberContact: json['rememberContact'] as bool? ?? false,
    itemFamily: json['itemFamily'] as String?,
    items: (json['items'] as List? ?? [])
        .map((item) => ReportItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    contact: json['contact'] == null
        ? ((json['flowVersion'] as int? ?? 1) < 2
              ? const ReportContact(anonymous: true)
              : null)
        : ReportContact.fromJson(json['contact'] as Map<String, dynamic>),
  );
}

class Report {
  Report({
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    String? photoPath,
    List<String>? photoPaths,
    this.debrisLocation,
    this.quantity,
    this.state = ReportState.notSent,
    this.serviceRequestNumber,
    this.contact,
    this.itemFamily,
    List<ReportItem> items = const [],
  }) : photoPaths = List.unmodifiable(photoPaths ?? [?photoPath]),
       items = List.unmodifiable(items);

  final String description;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<String> photoPaths;
  String? get photoPath => photoPaths.isEmpty ? null : photoPaths.first;
  final String? debrisLocation;
  final int? quantity;
  final ReportState state;
  final String? serviceRequestNumber;
  final ReportContact? contact;
  final String? itemFamily;
  final List<ReportItem> items;

  Map<String, dynamic> toJson() => {
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
    'photoPath': photoPath,
    if (photoPaths.length > 1) 'photoPaths': photoPaths,
    'debrisLocation': debrisLocation,
    'quantity': quantity,
    'state': state.name,
    'serviceRequestNumber': serviceRequestNumber,
    if (contact != null) 'contact': contact!.toJson(),
    if (itemFamily != null) 'itemFamily': itemFamily,
    if (items.isNotEmpty) 'items': items.map((item) => item.toJson()).toList(),
  };

  Report submittedWith(String serviceRequestNumber) => Report(
    description: description,
    latitude: latitude,
    longitude: longitude,
    createdAt: createdAt,
    photoPaths: photoPaths,
    debrisLocation: debrisLocation,
    quantity: quantity,
    state: ReportState.submitted,
    serviceRequestNumber: serviceRequestNumber,
    contact: contact,
    itemFamily: itemFamily,
    items: items,
  );

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    description: json['description'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    photoPath: json['photoPath'] as String?,
    photoPaths: (json['photoPaths'] as List?)?.cast<String>(),
    debrisLocation: json['debrisLocation'] as String?,
    quantity: (json['quantity'] as num?)?.toInt(),
    state: ReportState.values.byName(json['state'] as String),
    serviceRequestNumber: json['serviceRequestNumber'] as String?,
    itemFamily: json['itemFamily'] as String?,
    items: (json['items'] as List? ?? [])
        .map((item) => ReportItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    contact: json['contact'] == null
        ? null
        : ReportContact.fromJson(json['contact'] as Map<String, dynamic>),
  );
}
