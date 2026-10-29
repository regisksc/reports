class ReportItem {
  const ReportItem({required this.name, required this.quantity, this.location});

  final String name;
  final String quantity;
  final String? location;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'location': location,
  };

  factory ReportItem.fromJson(Map<String, dynamic> json) => ReportItem(
    name: json['name'] as String,
    quantity: json['quantity'] as String,
    location: json['location'] as String?,
  );
}
