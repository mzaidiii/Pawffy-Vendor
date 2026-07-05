class HomeDataModel {
  final HomeHeader header;
  final HomeApplicationStatus applicationStatus;
  final HomeBanner banner;
  final TodayAtAGlance todayAtAGlance;
  final List<BookingModel> upcomingBookings;
  final bool requestsAvailable;

  HomeDataModel({
    required this.header,
    required this.applicationStatus,
    required this.banner,
    required this.todayAtAGlance,
    required this.upcomingBookings,
    required this.requestsAvailable,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      header: HomeHeader.fromJson(json['header'] ?? {}),
      applicationStatus: HomeApplicationStatus.fromJson(json['applicationStatus'] ?? {}),
      banner: HomeBanner.fromJson(json['banner'] ?? {}),
      todayAtAGlance: TodayAtAGlance.fromJson(json['todayAtAGlance'] ?? {}),
      upcomingBookings: (json['upcomingBookings'] as List? ?? [])
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      requestsAvailable: json['requestsAvailable'] as bool? ?? false,
    );
  }
}

class HomeHeader {
  final String name;
  final String? businessName;
  final String location;
  final String? city;
  final String? state;
  final String? profileImage;
  final bool isOnline;
  final int unreadNotifications;

  HomeHeader({
    required this.name,
    this.businessName,
    required this.location,
    this.city,
    this.state,
    this.profileImage,
    required this.isOnline,
    required this.unreadNotifications,
  });

  factory HomeHeader.fromJson(Map<String, dynamic> json) {
    return HomeHeader(
      name: json['name'] ?? '',
      businessName: json['businessName'],
      location: json['location'] ?? '',
      city: json['city'],
      state: json['state'],
      profileImage: json['profileImage'],
      isOnline: json['isOnline'] as bool? ?? false,
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
    );
  }
}

class HomeApplicationStatus {
  final String status;
  final String label;
  final bool isVerified;
  final bool isPending;
  final bool isRejected;
  final String? rejectionReason;
  final String message;

  HomeApplicationStatus({
    required this.status,
    required this.label,
    required this.isVerified,
    required this.isPending,
    required this.isRejected,
    this.rejectionReason,
    required this.message,
  });

  factory HomeApplicationStatus.fromJson(Map<String, dynamic> json) {
    return HomeApplicationStatus(
      status: json['status'] ?? '',
      label: json['label'] ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? false,
      isRejected: json['isRejected'] as bool? ?? false,
      rejectionReason: json['rejectionReason'],
      message: json['message'] ?? '',
    );
  }
}

class HomeBanner {
  final int newRequestsCount;
  final String message;

  HomeBanner({
    required this.newRequestsCount,
    required this.message,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      newRequestsCount: json['newRequestsCount'] as int? ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class TodayAtAGlance {
  final GlanceItem schedule;
  final GlanceItem newRequests;
  final EarningsItem earnings;
  final RatingItem rating;

  TodayAtAGlance({
    required this.schedule,
    required this.newRequests,
    required this.earnings,
    required this.rating,
  });

  factory TodayAtAGlance.fromJson(Map<String, dynamic> json) {
    return TodayAtAGlance(
      schedule: GlanceItem.fromJson(json['schedule'] ?? {}),
      newRequests: GlanceItem.fromJson(json['newRequests'] ?? {}),
      earnings: EarningsItem.fromJson(json['earnings'] ?? {}),
      rating: RatingItem.fromJson(json['rating'] ?? {}),
    );
  }
}

class GlanceItem {
  final int count;
  final String label;

  GlanceItem({
    required this.count,
    required this.label,
  });

  factory GlanceItem.fromJson(Map<String, dynamic> json) {
    return GlanceItem(
      count: json['count'] as int? ?? 0,
      label: json['label'] ?? '',
    );
  }
}

class EarningsItem {
  final double amount;
  final String display;
  final double changePercent;
  final String changeLabel;

  EarningsItem({
    required this.amount,
    required this.display,
    required this.changePercent,
    required this.changeLabel,
  });

  factory EarningsItem.fromJson(Map<String, dynamic> json) {
    return EarningsItem(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      display: json['display'] ?? '\$0',
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
      changeLabel: json['changeLabel'] ?? '',
    );
  }
}

class RatingItem {
  final double average;
  final int reviewCount;

  RatingItem({
    required this.average,
    required this.reviewCount,
  });

  factory RatingItem.fromJson(Map<String, dynamic> json) {
    return RatingItem(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

class BookingModel {
  final String id;
  final String petName;
  final String? petPhoto;
  final String serviceName;
  final String location;
  final String time;
  final String priceDisplay;
  final double price;
  final String status;
  final String? date;

  BookingModel({
    required this.id,
    required this.petName,
    this.petPhoto,
    required this.serviceName,
    required this.location,
    required this.time,
    required this.priceDisplay,
    required this.price,
    required this.status,
    this.date,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      petName: json['petName']?.toString() ?? (json['pet'] != null ? (json['pet']['name'] ?? '') : ''),
      petPhoto: json['petPhoto']?.toString() ?? (json['pet'] != null ? json['pet']['photo'] : null),
      serviceName: json['serviceName']?.toString() ?? (json['service'] != null ? (json['service']['name'] ?? '') : ''),
      location: json['location']?.toString() ?? json['address']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      priceDisplay: json['priceDisplay']?.toString() ?? (json['price'] != null ? '\$${json['price']}' : '\$0'),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      date: json['date']?.toString(),
    );
  }
}
