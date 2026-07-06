class BlockedDateModel {
  final String id;
  final String date;
  final String? reason;

  BlockedDateModel({
    required this.id,
    required this.date,
    this.reason,
  });

  factory BlockedDateModel.fromJson(Map<String, dynamic> json) {
    return BlockedDateModel(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      reason: json['reason']?.toString(),
    );
  }
}
