class DoctorModel {
  final String doctorId;
  final String hospitalId;
  final String departmentId;
  final String name;
  final String specialization;
  final String schedule;
  final int dailyTokenLimit;

  const DoctorModel({
    required this.doctorId,
    required this.hospitalId,
    required this.departmentId,
    required this.name,
    required this.specialization,
    required this.schedule,
    required this.dailyTokenLimit,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      doctorId: (map['doctorId'] ?? '') as String,
      hospitalId: (map['hospitalId'] ?? '') as String,
      departmentId: (map['departmentId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      specialization: (map['specialization'] ?? '') as String,
      schedule: (map['schedule'] ?? '') as String,
      dailyTokenLimit: (map['dailyTokenLimit'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'departmentId': departmentId,
      'name': name,
      'specialization': specialization,
      'schedule': schedule,
      'dailyTokenLimit': dailyTokenLimit,
    };
  }
}
