class VendorServiceModel {
  final String id;
  final String serviceType;
  final String name;
  final String description;
  final List<String> inclusions;
  final int durationMinutes;
  final String priceType;
  final double? price;
  final double? minPrice;
  final double? maxPrice;
  final String priceDisplay;
  final String serviceLocation;
  final bool isActive;

  VendorServiceModel({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.inclusions,
    required this.durationMinutes,
    required this.priceType,
    this.price,
    this.minPrice,
    this.maxPrice,
    required this.priceDisplay,
    required this.serviceLocation,
    required this.isActive,
  });

  factory VendorServiceModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceModel(
      id: json['id']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      inclusions: (json['inclusions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : (int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0),
      priceType: json['priceType']?.toString() ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      minPrice: json['minPrice'] != null ? double.tryParse(json['minPrice'].toString()) : null,
      maxPrice: json['maxPrice'] != null ? double.tryParse(json['maxPrice'].toString()) : null,
      priceDisplay: json['priceDisplay']?.toString() ?? '',
      serviceLocation: json['serviceLocation']?.toString() ?? '',
      isActive: json['isActive'] is bool ? json['isActive'] : (json['isActive']?.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'name': name,
      'description': description,
      'inclusions': inclusions,
      'durationMinutes': durationMinutes,
      'priceType': priceType,
      'price': price,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceDisplay': priceDisplay,
      'serviceLocation': serviceLocation,
      'isActive': isActive,
    };
  }
}

class ProfileInfo {
  final String name;
  final String? title;
  final String? phone;
  final String? email;
  final String? location;
  final String? city;
  final String? state;
  final String? profileImage;
  final String? businessName;
  final String? description;

  ProfileInfo({
    required this.name,
    this.title,
    this.phone,
    this.email,
    this.location,
    this.city,
    this.state,
    this.profileImage,
    this.businessName,
    this.description,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      profileImage: json['profileImage']?.toString(),
      businessName: json['businessName']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class ProfileApplicationStatus {
  final String status;
  final String label;
  final bool isVerified;
  final bool isPending;
  final bool isRejected;
  final String? rejectionReason;
  final String message;

  ProfileApplicationStatus({
    required this.status,
    required this.label,
    required this.isVerified,
    required this.isPending,
    required this.isRejected,
    this.rejectionReason,
    required this.message,
  });

  factory ProfileApplicationStatus.fromJson(Map<String, dynamic> json) {
    return ProfileApplicationStatus(
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isVerified: json['isVerified'] is bool ? json['isVerified'] : (json['isVerified']?.toString() == 'true'),
      isPending: json['isPending'] is bool ? json['isPending'] : (json['isPending']?.toString() == 'true'),
      isRejected: json['isRejected'] is bool ? json['isRejected'] : (json['isRejected']?.toString() == 'true'),
      rejectionReason: json['rejectionReason']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}

class ProfileMembership {
  final String plan;
  final String label;
  final String? expiresAt;
  final String? validTill;
  final bool isPro;

  ProfileMembership({
    required this.plan,
    required this.label,
    this.expiresAt,
    this.validTill,
    required this.isPro,
  });

  factory ProfileMembership.fromJson(Map<String, dynamic> json) {
    return ProfileMembership(
      plan: json['plan']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString(),
      validTill: json['validTill']?.toString(),
      isPro: json['isPro'] is bool ? json['isPro'] : (json['isPro']?.toString() == 'true'),
    );
  }
}

class PerformanceStats {
  final String period;
  final StatCount totalBookings;
  final StatEarning totalEarning;
  final StatRating rating;
  final StatPercent repeatClients;

  PerformanceStats({
    required this.period,
    required this.totalBookings,
    required this.totalEarning,
    required this.rating,
    required this.repeatClients,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      period: json['period']?.toString() ?? 'month',
      totalBookings: StatCount.fromJson(json['totalBookings'] ?? {}),
      totalEarning: StatEarning.fromJson(json['totalEarning'] ?? {}),
      rating: StatRating.fromJson(json['rating'] ?? {}),
      repeatClients: StatPercent.fromJson(json['repeatClients'] ?? {}),
    );
  }
}

class StatCount {
  final int count;
  final double changePercent;

  StatCount({required this.count, required this.changePercent});

  factory StatCount.fromJson(Map<String, dynamic> json) {
    return StatCount(
      count: json['count'] is int ? json['count'] : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      changePercent: double.tryParse(json['changePercent']?.toString() ?? '') ?? 0.0,
    );
  }
}

class StatEarning {
  final double amount;
  final String display;
  final double changePercent;

  StatEarning({required this.amount, required this.display, required this.changePercent});

  factory StatEarning.fromJson(Map<String, dynamic> json) {
    return StatEarning(
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      display: json['display']?.toString() ?? '\$0',
      changePercent: double.tryParse(json['changePercent']?.toString() ?? '') ?? 0.0,
    );
  }
}

class StatRating {
  final double average;
  final int reviewCount;

  StatRating({required this.average, required this.reviewCount});

  factory StatRating.fromJson(Map<String, dynamic> json) {
    return StatRating(
      average: double.tryParse(json['average']?.toString() ?? '') ?? 0.0,
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] : (int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0),
    );
  }
}

class StatPercent {
  final double percent;
  final double changePercent;

  StatPercent({required this.percent, required this.changePercent});

  factory StatPercent.fromJson(Map<String, dynamic> json) {
    return StatPercent(
      percent: double.tryParse(json['percent']?.toString() ?? '') ?? 0.0,
      changePercent: double.tryParse(json['changePercent']?.toString() ?? '') ?? 0.0,
    );
  }
}

class VendorProfileModel {
  final ProfileInfo profile;
  final ProfileApplicationStatus applicationStatus;
  final ProfileMembership membership;
  final PerformanceStats performance;
  final List<VendorServiceModel> services;
  final int unreadNotifications;
  final bool isOnline;

  VendorProfileModel({
    required this.profile,
    required this.applicationStatus,
    required this.membership,
    required this.performance,
    required this.services,
    required this.unreadNotifications,
    required this.isOnline,
  });

  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return VendorProfileModel(
      profile: ProfileInfo.fromJson(data['profile'] ?? {}),
      applicationStatus: ProfileApplicationStatus.fromJson(data['applicationStatus'] ?? {}),
      membership: ProfileMembership.fromJson(data['membership'] ?? {}),
      performance: PerformanceStats.fromJson(data['performance'] ?? {}),
      services: (data['services'] as List?)?.map((e) => VendorServiceModel.fromJson(e)).toList() ?? [],
      unreadNotifications: data['unreadNotifications'] is int ? data['unreadNotifications'] : (int.tryParse(data['unreadNotifications']?.toString() ?? '') ?? 0),
      isOnline: data['isOnline'] is bool ? data['isOnline'] : (data['isOnline']?.toString() == 'true'),
    );
  }
}
