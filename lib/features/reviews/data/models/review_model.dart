class CustomerReviewModel {
  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? replyContent;
  final String customerName;
  final String? customerPhoto;
  final String bookingServiceName;
  final String bookingId;

  CustomerReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.replyContent,
    required this.customerName,
    this.customerPhoto,
    required this.bookingServiceName,
    required this.bookingId,
  });

  factory CustomerReviewModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final bookingJson = json['booking'] as Map<String, dynamic>?;

    final String custName = userJson?['name']?.toString() ??
        customerJson?['name']?.toString() ??
        json['customerName']?.toString() ??
        'Anonymous Customer';

    final String? custPhoto = userJson?['avatar']?.toString() ??
        userJson?['photo']?.toString() ??
        customerJson?['photo']?.toString() ??
        customerJson?['avatar']?.toString() ??
        json['customerPhoto']?.toString();

    final String servName = bookingJson?['serviceName']?.toString() ??
        json['bookingServiceName']?.toString() ??
        'Pet Service';

    final String bookId = bookingJson?['id']?.toString() ??
        json['bookingId']?.toString() ??
        '';

    return CustomerReviewModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : (int.tryParse(json['rating']?.toString() ?? '') ?? 5),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      replyContent: json['replyContent']?.toString(),
      customerName: custName,
      customerPhoto: custPhoto,
      bookingServiceName: servName,
      bookingId: bookId,
    );
  }
}

class VendorReviewModel {
  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String bookingId;
  final String customerName;
  final String? customerPhoto;

  VendorReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.bookingId,
    required this.customerName,
    this.customerPhoto,
  });

  factory VendorReviewModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final userJson = json['user'] as Map<String, dynamic>?;
    final bookingJson = json['booking'] as Map<String, dynamic>?;

    final String custName = customerJson?['name']?.toString() ??
        userJson?['name']?.toString() ??
        json['customerName']?.toString() ??
        'Customer';

    final String? custPhoto = customerJson?['photo']?.toString() ??
        customerJson?['avatar']?.toString() ??
        userJson?['avatar']?.toString() ??
        json['customerPhoto']?.toString();

    return VendorReviewModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : (int.tryParse(json['rating']?.toString() ?? '') ?? 5),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      bookingId: json['bookingId']?.toString() ?? bookingJson?['id']?.toString() ?? '',
      customerName: custName,
      customerPhoto: custPhoto,
    );
  }
}
