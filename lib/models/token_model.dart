class TokenModel {
  final String tokenId;
  final String hospitalId;
  final String doctorId;
  final String patientId;
  final int tokenNumber;
  final String status;
  final int priority;
  final DateTime bookedAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final String date;

  const TokenModel({
    required this.tokenId,
    required this.hospitalId,
    required this.doctorId,
    required this.patientId,
    required this.tokenNumber,
    required this.status,
    required this.priority,
    required this.bookedAt,
    this.startTime,
    this.endTime,
    required this.date,
  });

  factory TokenModel.fromMap(Map<String, dynamic> map) {
    return TokenModel(
      tokenId: (map['tokenId'] ?? map['id']?.toString() ?? '') as String,
      hospitalId: (map['hospitalId'] ?? map['hospital_id']?.toString() ?? '') as String,
      doctorId: (map['doctorId'] ?? map['doctor_id']?.toString() ?? '') as String,
      patientId: (map['patientId'] ?? map['patient_id']?.toString() ?? '') as String,
      tokenNumber: (map['tokenNumber'] ?? map['token_number'] ?? 0) as int,
      status: (map['status'] ?? '') as String,
      priority: (map['priority'] ?? 0) as int,
      bookedAt: map['bookedAt'] != null
          ? DateTime.parse(map['bookedAt'])
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : (map['called_at'] != null ? DateTime.parse(map['called_at']) : null),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'])
          : (map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null),
      date: (map['date'] ?? map['booking_date'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tokenId': tokenId,
      'hospitalId': hospitalId,
      'doctorId': doctorId,
      'patientId': patientId,
      'tokenNumber': tokenNumber,
      'status': status,
      'priority': priority,
      'bookedAt': bookedAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'date': date,
    };
  }
}
