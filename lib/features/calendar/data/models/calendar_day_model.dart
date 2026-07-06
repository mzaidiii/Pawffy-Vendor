import 'package:pawffy/features/home/data/models/home_data_model.dart';

class CalendarDayModel {
  final String date;
  final bool isOnline;
  final bool isBlocked;
  final String? blockedReason;
  final CalendarBannerModel banner;
  final List<BookingModel> schedule;

  CalendarDayModel({
    required this.date,
    required this.isOnline,
    required this.isBlocked,
    this.blockedReason,
    required this.banner,
    required this.schedule,
  });

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayModel(
      date: json['date']?.toString() ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedReason: json['blockedReason']?.toString(),
      banner: CalendarBannerModel.fromJson(json['banner'] ?? {}),
      schedule: (json['schedule'] as List? ?? [])
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CalendarBannerModel {
  final int newRequestsCount;
  final String message;

  CalendarBannerModel({
    required this.newRequestsCount,
    required this.message,
  });

  factory CalendarBannerModel.fromJson(Map<String, dynamic> json) {
    return CalendarBannerModel(
      newRequestsCount: json['newRequestsCount'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}
