export 'report_contact.dart';

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
  }) : photoPaths = List.unmodifiable(photoPaths ?? [?photoPath]);

  final DateTime createdAt;
  final String description;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
  String? get photoPath => photoPaths.isEmpty ? null : photoPaths.first;
  final String? debrisLocation;
  final String quantity;
  final int step;

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
    step: json['step'] as int,
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
  }) : photoPaths = List.unmodifiable(photoPaths ?? [?photoPath]);

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
  );
}
