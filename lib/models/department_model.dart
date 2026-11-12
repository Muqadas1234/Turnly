class DepartmentModel {
  final String departmentId;
  final String hospitalId;
  final String name;

  const DepartmentModel({
    required this.departmentId,
    required this.hospitalId,
    required this.name,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      departmentId: (map['departmentId'] ?? '') as String,
      hospitalId: (map['hospitalId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'hospitalId': hospitalId,
      'name': name,
    };
  }
}
