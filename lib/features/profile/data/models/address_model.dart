class AddressModel {
  final String id;
  final String label;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      address: json['address']?.toString() ?? json['streetAddress']?.toString() ?? json['fullAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? json['pinCode']?.toString() ?? json['postalCode']?.toString() ?? json['zipCode']?.toString() ?? '',
      isDefault: json['isDefault'] is bool
          ? json['isDefault']
          : (json['isDefault']?.toString() == 'true' || json['isPrimary']?.toString() == 'true' || json['isPrimary'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
