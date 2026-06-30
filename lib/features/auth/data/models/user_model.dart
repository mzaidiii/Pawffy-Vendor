class UserModel {
  final String id;
  final String? clerkId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profileImage;
  final String? address;
  final String? city;
  final String? state;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.clerkId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.address,
    this.city,
    this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      clerkId: json['clerkId'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      profileImage: json['profileImage'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clerkId': clerkId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'address': address,
      'city': city,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
