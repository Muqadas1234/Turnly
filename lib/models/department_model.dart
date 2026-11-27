class DepartmentModel {
  final String departmentId;
  final String hospitalId;
  final String name;
  final String description;
  final int dailyTokenLimit;
  final bool isActive;
  final int doctorCount;
  final String iconKey;

  const DepartmentModel({
    required this.departmentId,
    required this.hospitalId,
    required this.name,
    this.description = '',
    this.dailyTokenLimit = 50,
    this.isActive = true,
    this.doctorCount = 0,
    this.iconKey = 'general',
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      departmentId: (map['departmentId'] ?? map['id'] ?? '').toString(),
      hospitalId: (map['hospitalId'] ?? map['hospital_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      dailyTokenLimit: int.tryParse((map['dailyTokenLimit'] ?? map['daily_token_limit'] ?? 50).toString()) ?? 50,
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      doctorCount: int.tryParse((map['doctorCount'] ?? map['doctor_count'] ?? 0).toString()) ?? 0,
      iconKey: (map['iconKey'] ?? map['icon_key'] ?? 'general').toString(),
    );
  }

  DepartmentModel copyWith({
    String? departmentId,
    String? hospitalId,
    String? name,
    String? description,
    int? dailyTokenLimit,
    bool? isActive,
    int? doctorCount,
    String? iconKey,
  }) {
    return DepartmentModel(
      departmentId: departmentId ?? this.departmentId,
      hospitalId: hospitalId ?? this.hospitalId,
      name: name ?? this.name,
      description: description ?? this.description,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
      isActive: isActive ?? this.isActive,
      doctorCount: doctorCount ?? this.doctorCount,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'hospital_id': hospitalId,
      'name': name,
      'description': description,
      'daily_token_limit': dailyTokenLimit,
      'is_active': isActive,
      'doctor_count': doctorCount,
      'icon_key': iconKey,
    };
  }
}
