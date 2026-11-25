import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/department_model.dart';
import '../models/hospital_model.dart';
import '../services/api_service.dart';
import '../utils/routes.dart';

/// ViewModel for the manager screens: holds state (Rx) and business logic.
class ManagerViewModel extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  Timer? _statusTimer;


  void startStatusPolling() {
    if (_statusTimer != null && _statusTimer!.isActive) return;
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await loadMyHospital(routeByStatus: true);
    });
  }

  void stopStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  // --- Hospital Registration (Steps 1-4) ---
  final currentStep = 1.obs;
  final isResubmitting = false.obs;

  // Step 1: Hospital details
  final hospitalNameC = TextEditingController(text: 'City General Hospital');
  final hospitalType = 'Private'.obs;
  final cityC = TextEditingController(text: 'Karachi');
  final addressC = TextEditingController();
  final opdTimingsC = TextEditingController(text: '9:00 AM - 8:00 PM');

  // Step 2 (M6): Manager details
  final managerNameC = TextEditingController(text: 'Dr. Farhan Ali');
  final managerEmailC = TextEditingController(text: 'farhan@cgh.pk');
  final managerPhoneC = TextEditingController(text: '+92 300 5551234');
  final managerDesignation = 'Medical Superintendent'.obs;
  final isAuthorizedConfirmed = true.obs;

  static const List<String> hospitalTypes = [
    'Private',
    'Government',
    'Trust / NGO',
  ];

  static const List<String> designations = [
    'Medical Superintendent',
    'Hospital Director',
    'Operations Manager',
    'Administrator',
  ];

  //  Logo & verification documents
  final logoFileName = ''.obs;
  final logoFileSize = ''.obs;
  final logoUrl = ''.obs;
  final logoBase64 = ''.obs;

  // License document (file 1) - required
  final licenseDocName = ''.obs;
  final licenseDocSize = ''.obs;
  final licenseDocUrl = ''.obs;
  final documentBase64 = ''.obs;
  final documentType = 'application/pdf'.obs;

  // Registration certificate (file 2) - optional
  final certificateDocName = ''.obs;
  final certificateDocSize = ''.obs;
  final certificateDocUrl = ''.obs;
  final certificateBase64 = ''.obs;
  final certificateDataType = 'application/pdf'.obs;

  // Review & submit
  final isTermsConfirmed = true.obs;

  //  Current Hospital Status
  final currentHospital = Rxn<HospitalModel>();

  // Manage Departments
  final departments = <DepartmentModel>[].obs;
  final departmentSearchQuery = ''.obs;

  List<DepartmentModel> get filteredDepartments {
    final q = departmentSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return departments;
    return departments.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _seedDefaultDepartmentsIfEmpty();
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    super.onClose();
  }



  void _seedDefaultDepartmentsIfEmpty() {
    if (departments.isEmpty) {
      departments.assignAll([
        const DepartmentModel(
          departmentId: '1',
          hospitalId: '1',
          name: 'Cardiology',
          doctorCount: 3,
          dailyTokenLimit: 120,
          isActive: true,
          iconKey: 'cardiology',
        ),
        const DepartmentModel(
          departmentId: '2',
          hospitalId: '1',
          name: 'Neurology',
          doctorCount: 2,
          dailyTokenLimit: 80,
          isActive: true,
          iconKey: 'neurology',
        ),
        const DepartmentModel(
          departmentId: '3',
          hospitalId: '1',
          name: 'Pediatrics',
          doctorCount: 4,
          dailyTokenLimit: 160,
          isActive: true,
          iconKey: 'pediatrics',
        ),
        const DepartmentModel(
          departmentId: '4',
          hospitalId: '1',
          name: 'Orthopedics',
          doctorCount: 1,
          dailyTokenLimit: 30,
          isActive: false,
          iconKey: 'orthopedics',
        ),
      ]);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 4) {
      currentStep.value = step;
    }
  }

  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value += 1;
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value -= 1;
    } else {
      Get.back();
    }
  }

  void attachLogo({required String name, required String size, String url = '', String base64 = ''}) {
    logoFileName.value = name;
    logoFileSize.value = size;
    logoUrl.value = url;
    logoBase64.value = base64;
  }

  void attachLicense({
    required String name,
    required String size,
    String url = '',
    String base64 = '',
    String mimeType = 'application/pdf',
  }) {
    licenseDocName.value = name;
    licenseDocSize.value = size;
    licenseDocUrl.value = url;
    documentBase64.value = base64;
    documentType.value = mimeType;
  }

  void attachCertificate({
    required String name,
    required String size,
    String url = '',
    String base64 = '',
    String mimeType = 'application/pdf',
  }) {
    certificateDocName.value = name;
    certificateDocSize.value = size;
    certificateDocUrl.value = url;
    certificateBase64.value = base64;
    certificateDataType.value = mimeType;
  }

  void prefillFromHospital(HospitalModel hospital) {
    hospitalNameC.text = hospital.name;
    if (hospitalTypes.contains(hospital.hospitalType)) {
      hospitalType.value = hospital.hospitalType;
    }
    cityC.text = hospital.city;
    addressC.text = hospital.address;
    opdTimingsC.text = hospital.opdTimings.isNotEmpty ? hospital.opdTimings : '9:00 AM - 8:00 PM';

    if (hospital.managerName.isNotEmpty) managerNameC.text = hospital.managerName;
    if (hospital.managerEmail.isNotEmpty) managerEmailC.text = hospital.managerEmail;
    if (hospital.managerPhone.isNotEmpty) managerPhoneC.text = hospital.managerPhone;
    if (designations.contains(hospital.managerDesignation)) {
      managerDesignation.value = hospital.managerDesignation;
    }

    licenseDocName.value = hospital.licenseDocName;
    licenseDocSize.value = hospital.licenseDocSize;
    licenseDocUrl.value = hospital.licenseDocUrl;
    certificateDocName.value = hospital.certificateDocName;
    certificateDocSize.value = hospital.certificateDocSize;
    certificateDocUrl.value = hospital.certificateDocUrl;
    logoUrl.value = hospital.logoUrl;
  }

  Future<void> submitRegistration() async {
    if (!isTermsConfirmed.value) {
      Get.snackbar(
        'Confirmation Required',
        'Please confirm that the information is accurate and agree to the Turnly Terms.',
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final payload = {
        'name': hospitalNameC.text.trim(),
        'hospital_type': hospitalType.value,
        'city': cityC.text.trim(),
        'address': addressC.text.trim(),
        'opd_timings': opdTimingsC.text.trim(),
        'logo_url': logoUrl.value.isNotEmpty ? logoUrl.value : logoFileName.value,
        'manager_name': managerNameC.text.trim(),
        'manager_email': managerEmailC.text.trim(),
        'manager_phone': managerPhoneC.text.trim(),
        'manager_designation': managerDesignation.value,
        'license_doc_name': licenseDocName.value.isNotEmpty ? licenseDocName.value : null,
        'license_doc_size': licenseDocSize.value.isNotEmpty ? licenseDocSize.value : null,
        'license_doc_url': licenseDocUrl.value.isNotEmpty ? licenseDocUrl.value : null,
        'certificate_doc_name': certificateDocName.value.isNotEmpty ? certificateDocName.value : null,
        'certificate_doc_size': certificateDocSize.value.isNotEmpty ? certificateDocSize.value : null,
        'certificate_doc_url': certificateDocUrl.value.isNotEmpty ? certificateDocUrl.value : null,
        // Logo binary
        'logo_base64': logoBase64.value.isNotEmpty ? logoBase64.value : null,
        'logo_name': logoFileName.value.isNotEmpty ? logoFileName.value : null,
        // License document binary
        'document_base64': documentBase64.value.isNotEmpty ? documentBase64.value : null,
        'document_name': licenseDocName.value.isNotEmpty ? licenseDocName.value : null,
        'document_type': documentType.value.isNotEmpty ? documentType.value : 'application/pdf',
        // Certificate document binary
        'certificate_base64': certificateBase64.value.isNotEmpty ? certificateBase64.value : null,
        'certificate_data_type': certificateDataType.value.isNotEmpty ? certificateDataType.value : 'application/pdf',
      };

      final response = isResubmitting.value
          ? await ApiService.resubmitHospital(payload)
          : await ApiService.registerHospital(payload);

      if (response['success'] == true) {
        if (response['hospital'] is Map<String, dynamic>) {
          currentHospital.value = HospitalModel.fromMap(
            Map<String, dynamic>.from(response['hospital'] as Map),
          );
        }
        isResubmitting.value = false;
        Get.snackbar(
          'Submitted',
          response['message'] ?? 'Hospital registration submitted for approval',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
        // Navigate to pending approval view to await admin review
        Get.offAllNamed(AppRoutes.pendingApproval);
      } else {
        errorMessage.value = response['message'] ?? 'Submission failed';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to reach server. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyHospital({bool routeByStatus = false}) async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMyHospital();
      if (response['success'] == true && response['hospital'] is Map) {
        final hosp = HospitalModel.fromMap(
          Map<String, dynamic>.from(response['hospital'] as Map),
        );
        currentHospital.value = hosp;
        if (routeByStatus) {
          if (hosp.status == 'approved') {
            stopStatusPolling();
            Get.offAllNamed(AppRoutes.managerDashboard);
          } else if (hosp.status == 'pending') {
            Get.offAllNamed(AppRoutes.pendingApproval);
          } else if (hosp.status == 'rejected') {
            stopStatusPolling();
            Get.offAllNamed(AppRoutes.registrationRejected);
          } else if (hosp.status == 'suspended') {
            stopStatusPolling();
            Get.offAllNamed(AppRoutes.hospitalSuspended);
          }
        }
      } else if (routeByStatus) {
        // No hospital registered yet -> start registration flow automatically
        currentStep.value = 1;
        Get.offAllNamed(AppRoutes.registrationForm);
      }
    } catch (_) {
      // Keep current state if offline
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDepartments() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getDepartments(
        search: departmentSearchQuery.value,
      );
      if (response['success'] == true && response['departments'] is List) {
        final list = (response['departments'] as List)
            .whereType<Map>()
            .map((e) => DepartmentModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        departments.assignAll(list);
      }
    } catch (_) {
      // Keep local list if offline
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleDepartment(DepartmentModel dept, bool value) async {
    final index = departments.indexWhere((d) => d.departmentId == dept.departmentId);
    if (index != -1) {
      departments[index] = dept.copyWith(isActive: value);
    }

    try {
      final response = await ApiService.toggleDepartment(
        dept.departmentId,
        isActive: value,
      );
      if (response['success'] != true && index != -1) {
        departments[index] = dept;
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to update department',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (_) {
      // Keep optimistic toggle if server is offline during local testing
    }
  }

  Future<void> addDepartment({
    required String name,
    String description = '',
    int dailyTokenLimit = 50,
    String iconKey = 'general',
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiService.createDepartment({
        'name': name.trim(),
        'description': description.trim(),
        'daily_token_limit': dailyTokenLimit,
        'is_active': true,
        'icon_key': iconKey,
      });

      if (response['success'] == true && response['department'] is Map) {
        final created = DepartmentModel.fromMap(
          Map<String, dynamic>.from(response['department'] as Map),
        );
        departments.add(created);
        Get.back();
        Get.snackbar(
          'Added',
          '${created.name} department added',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
      } else {
        final localDept = DepartmentModel(
          departmentId: DateTime.now().millisecondsSinceEpoch.toString(),
          hospitalId: currentHospital.value?.hospitalId ?? '1',
          name: name.trim(),
          description: description.trim(),
          dailyTokenLimit: dailyTokenLimit,
          isActive: true,
          doctorCount: 0,
          iconKey: iconKey,
        );
        departments.add(localDept);
        Get.back();
      }
    } catch (_) {
      final localDept = DepartmentModel(
        departmentId: DateTime.now().millisecondsSinceEpoch.toString(),
        hospitalId: currentHospital.value?.hospitalId ?? '1',
        name: name.trim(),
        description: description.trim(),
        dailyTokenLimit: dailyTokenLimit,
        isActive: true,
        doctorCount: 0,
        iconKey: iconKey,
      );
      departments.add(localDept);
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  
}
