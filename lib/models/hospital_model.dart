class HospitalModel {
  final String hospitalId;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String opdTimings;
  final String status;
  final String managerId;

  const HospitalModel({
    required this.hospitalId,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.opdTimings,
    required this.status,
    required this.managerId,
  });

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      hospitalId: (map['hospitalId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      opdTimings: (map['opdTimings'] ?? '') as String,
      status: (map['status'] ?? '') as String,
      managerId: (map['managerId'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'name': name,
      'city': city,
      'address': address,
      'phone': phone,
      'opdTimings': opdTimings,
      'status': status,
      'managerId': managerId,
    };
  }
}
