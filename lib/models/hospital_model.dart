class HospitalModel {
  final String hospitalId;
  final String name;
  final String hospitalType;
  final String city;
  final String address;
  final String phone;
  final String email;
  final String opdTimings;
  final String logoUrl;
  final String status;
  final String managerId;
  final String managerName;
  final String managerEmail;
  final String managerPhone;
  final String managerDesignation;
  final String licenseDocName;
  final String licenseDocSize;
  final String licenseDocUrl;
  final String certificateDocName;
  final String certificateDocSize;
  final String certificateDocUrl;
  final String rejectionReason;
  final String suspensionReason;

  const HospitalModel({
    required this.hospitalId,
    required this.name,
    this.hospitalType = 'Private',
    required this.city,
    required this.address,
    required this.phone,
    this.email = '',
    required this.opdTimings,
    this.logoUrl = '',
    required this.status,
    required this.managerId,
    this.managerName = '',
    this.managerEmail = '',
    this.managerPhone = '',
    this.managerDesignation = 'Medical Superintendent',
    this.licenseDocName = '',
    this.licenseDocSize = '',
    this.licenseDocUrl = '',
    this.certificateDocName = '',
    this.certificateDocSize = '',
    this.certificateDocUrl = '',
    this.rejectionReason = '',
    this.suspensionReason = '',
  });

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      hospitalId: (map['hospitalId'] ?? map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      hospitalType: (map['hospitalType'] ?? map['hospital_type'] ?? 'Private').toString(),
      city: (map['city'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      opdTimings: (map['opdTimings'] ?? map['opd_timings'] ?? '').toString(),
      logoUrl: (map['logoUrl'] ?? map['logo_url'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      managerId: (map['managerId'] ?? map['manager_id'] ?? '').toString(),
      managerName: (map['managerName'] ?? map['manager_name'] ?? '').toString(),
      managerEmail: (map['managerEmail'] ?? map['manager_email'] ?? '').toString(),
      managerPhone: (map['managerPhone'] ?? map['manager_phone'] ?? '').toString(),
      managerDesignation: (map['managerDesignation'] ?? map['manager_designation'] ?? 'Medical Superintendent').toString(),
      licenseDocName: (map['licenseDocName'] ?? map['license_doc_name'] ?? '').toString(),
      licenseDocSize: (map['licenseDocSize'] ?? map['license_doc_size'] ?? '').toString(),
      licenseDocUrl: (map['licenseDocUrl'] ?? map['license_doc_url'] ?? '').toString(),
      certificateDocName: (map['certificateDocName'] ?? map['certificate_doc_name'] ?? '').toString(),
      certificateDocSize: (map['certificateDocSize'] ?? map['certificate_doc_size'] ?? '').toString(),
      certificateDocUrl: (map['certificateDocUrl'] ?? map['certificate_doc_url'] ?? '').toString(),
      rejectionReason: (map['rejectionReason'] ?? map['rejection_reason'] ?? '').toString(),
      suspensionReason: (map['suspensionReason'] ?? map['suspension_reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'name': name,
      'hospital_type': hospitalType,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'opd_timings': opdTimings,
      'logo_url': logoUrl,
      'status': status,
      'manager_id': managerId,
      'manager_name': managerName,
      'manager_email': managerEmail,
      'manager_phone': managerPhone,
      'manager_designation': managerDesignation,
      'license_doc_name': licenseDocName,
      'license_doc_size': licenseDocSize,
      'license_doc_url': licenseDocUrl,
      'certificate_doc_name': certificateDocName,
      'certificate_doc_size': certificateDocSize,
      'certificate_doc_url': certificateDocUrl,
      'rejection_reason': rejectionReason,
      'suspension_reason': suspensionReason,
    };
  }
}
