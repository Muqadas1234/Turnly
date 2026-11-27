class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? hospitalId;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.hospitalId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: (map['uid'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      role: (map['role'] ?? '') as String,
      hospitalId: map['hospitalId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'hospitalId': hospitalId,
    };
  }
}
