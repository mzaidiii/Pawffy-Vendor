class AvailabilityModel {
  final List<String> workingDays;
  final String startTime;
  final String endTime;
  final bool sameDayRequests;

  AvailabilityModel({
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    required this.sameDayRequests,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      workingDays: List<String>.from(json['workingDays'] ?? []),
      startTime: json['startTime']?.toString() ?? '09:00 AM',
      endTime: json['endTime']?.toString() ?? '06:00 PM',
      sameDayRequests: json['sameDayRequests'] as bool? ?? false,
    );
  }
}
