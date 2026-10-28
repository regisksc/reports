class ReportContact {
  const ReportContact({
    required this.anonymous,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
  });

  final bool anonymous;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
    'anonymous': anonymous,
    'first': firstName,
    'last': lastName,
    'email': email,
    'phone': phone,
  };

  factory ReportContact.fromJson(Map<String, dynamic> json) => ReportContact(
    anonymous: json['anonymous'] as bool? ?? false,
    firstName: json['first'] as String? ?? '',
    lastName: json['last'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}
