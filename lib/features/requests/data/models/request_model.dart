import 'package:intl/intl.dart';

class PetModel {
  final String id;
  final String name;
  final String? photo;
  final String? breed;
  final String? age;
  final String? gender;

  PetModel({
    required this.id,
    required this.name,
    this.photo,
    this.breed,
    this.age,
    this.gender,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    // Standardize age display (e.g. from ageYears or raw age)
    String? ageStr = json['age']?.toString();
    if (ageStr == null && json['ageYears'] != null) {
      ageStr = '${json['ageYears']} year';
    }

    return PetModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Pet',
      photo: json['photo']?.toString() ?? json['profileImage']?.toString(),
      breed: json['breed']?.toString(),
      age: ageStr,
      gender: json['gender']?.toString(),
    );
  }
}

class RequestModel {
  final String id;
  final String status;
  final String serviceName;
  final String? serviceType;
  final String location;
  final String time;
  final String? date;
  final double price;
  final String priceDisplay;
  final int durationMinutes;
  final String? issues;
  final String? notes;
  final PetModel? pet;

  RequestModel({
    required this.id,
    required this.status,
    required this.serviceName,
    this.serviceType,
    required this.location,
    required this.time,
    this.date,
    required this.price,
    required this.priceDisplay,
    required this.durationMinutes,
    this.issues,
    this.notes,
    this.pet,
  });

  String get formattedDateTime {
    final cleanTime = time.trim();
    final cleanDate = date?.trim();

    if ((cleanDate == null || cleanDate.isEmpty) && cleanTime.isEmpty) {
      return 'N/A';
    }

    String formattedDateStr = '';
    String formattedTimeStr = cleanTime;

    if (cleanDate != null && cleanDate.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(cleanDate).toLocal();
        formattedDateStr = DateFormat('dd MMM yyyy').format(parsedDate);
        if ((formattedTimeStr.isEmpty || formattedTimeStr == '00:00' || formattedTimeStr == '00:00:00') &&
            (parsedDate.hour != 0 || parsedDate.minute != 0)) {
          formattedTimeStr = DateFormat('h:mm a').format(parsedDate);
        }
      } catch (_) {
        formattedDateStr = cleanDate.split('T').first;
      }
    }

    if (formattedTimeStr == '00:00' || formattedTimeStr == '00:00:00') {
      formattedTimeStr = '';
    }

    if (formattedDateStr.isNotEmpty && formattedTimeStr.isNotEmpty) {
      return '$formattedDateStr at $formattedTimeStr';
    } else if (formattedDateStr.isNotEmpty) {
      return formattedDateStr;
    } else {
      return formattedTimeStr;
    }
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    final petJson = json['pet'] as Map<String, dynamic>?;
    final serviceJson = json['service'] as Map<String, dynamic>?;

    final double rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    final String priceStr = json['priceDisplay']?.toString() ?? (json['price'] != null ? '\$${json['price']}' : '\$0');

    // Handle date formatting if raw date exists
    final String timeStr = json['time']?.toString() ?? json['bookingTime']?.toString() ?? json['booking_time']?.toString() ?? '';

    return RequestModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      serviceName: json['serviceName']?.toString() ?? serviceJson?['name']?.toString() ?? 'Consultancy',
      serviceType: json['serviceType']?.toString() ?? serviceJson?['serviceType']?.toString(),
      location: json['location']?.toString() ?? json['address']?.toString() ?? '',
      time: timeStr,
      date: json['date']?.toString() ?? json['bookingDate']?.toString() ?? json['booking_date']?.toString(),
      price: rawPrice,
      priceDisplay: priceStr,
      durationMinutes: json['durationMinutes'] as int? ?? json['duration'] as int? ?? 30,
      issues: json['issues']?.toString() ?? json['issue']?.toString(),
      notes: json['notes']?.toString() ?? json['ownersNote']?.toString() ?? json['ownerNote']?.toString(),
      pet: petJson != null ? PetModel.fromJson(petJson) : null,
    );
  }
}
