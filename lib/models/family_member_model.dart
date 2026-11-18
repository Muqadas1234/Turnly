class FamilyMemberModel {
  final String memberId;
  final String userId;
  final String name;
  final int age;
  final String relation;

  const FamilyMemberModel({
    required this.memberId,
    required this.userId,
    required this.name,
    required this.age,
    required this.relation,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyMemberModel(
      memberId: (map['memberId'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      age: (map['age'] ?? 0) as int,
      relation: (map['relation'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'userId': userId,
      'name': name,
      'age': age,
      'relation': relation,
    };
  }
}
