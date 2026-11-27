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

  // --- Manager Dashboard Live Stats & Queues ---
  final tokensToday = 0.obs;
  final inQueueNow = 0.obs;
  final patientsServed = 0.obs;
  final avgConsultationMins = 0.obs;
  final todayQueues = <Map<String, dynamic>>[].obs;
  final todayTokens = <Map<String, dynamic>>[].obs;
  final isDashboardLoading = false.obs;

  int _dashboardInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> fetchDashboard({String? date}) async {
    isDashboardLoading.value = true;
    try {
      final response = await ApiService.getManagerDashboard(date: date);
      if (response['success'] == true) {
        // Backend: GET /api/queue/stats -> { success, stats: { tokens_issued, in_queue,
        // served, avg_consult_minutes, doctors: [...] } }
        final raw = response['stats'] is Map
            ? Map<String, dynamic>.from(response['stats'] as Map)
            : <String, dynamic>{};
        tokensToday.value = _dashboardInt(raw['tokens_issued']);
        inQueueNow.value = _dashboardInt(raw['in_queue']);
        patientsServed.value = _dashboardInt(raw['served']);
        avgConsultationMins.value = _dashboardInt(raw['avg_consult_minutes']);
        final queueData = raw['doctors'];
        if (queueData is List) {
          todayQueues.assignAll(
            queueData.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
        } else {
          todayQueues.clear();
        }
        final tokensData = raw['tokens'];
        if (tokensData is List) {
          todayTokens.assignAll(
            tokensData.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
        } else {
          todayTokens.clear();
        }
        errorMessage.value = '';
      } else {
        errorMessage.value =
            response['message']?.toString() ??
            'Dashboard data could not be loaded.';
      }
    } catch (e) {
      errorMessage.value = 'Could not load live dashboard data: $e';
    } finally {
      isDashboardLoading.value = false;
    }
  }

  void startStatusPolling() {
    if (_statusTimer != null && _statusTimer!.isActive) return;
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkStatusSilently();
    });
  }

  void stopStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _checkStatusSilently() async {
    try {
      final response = await ApiService.getMyHospital();
      final rawHospital = response['hospital'] ?? response['data'];
      if (response['success'] == true && rawHospital is Map) {
        final hosp = HospitalModel.fromMap(
          Map<String, dynamic>.from(rawHospital),
        );
        final newStatus = hosp.status.trim().toLowerCase();
        currentHospital.value = hosp;

        if (newStatus != 'pending' && newStatus.isNotEmpty) {
          stopStatusPolling();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _routeBasedOnHospital(hosp);
          });
        }
      }
    } catch (_) {}
  }

  void _routeBasedOnHospital(HospitalModel hosp) {
    final status = hosp.status.trim().toLowerCase();
    if (status == 'approved') {
      stopStatusPolling();
      Get.offAllNamed(AppRoutes.managerDashboard);
    } else if (status == 'rejected') {
      stopStatusPolling();
      isResubmitting.value = true;
      prefillFromHospital(hosp);
      Get.offAllNamed(AppRoutes.registrationRejected);
    } else if (status == 'suspended') {
      stopStatusPolling();
      Get.offAllNamed(AppRoutes.hospitalSuspended);
    } else if (status == 'pending') {
      Get.offAllNamed(AppRoutes.pendingApproval);
      startStatusPolling();
    } else {
      Get.offAllNamed(AppRoutes.registrationForm);
    }
  }

  // --- Hospital Registration (Steps 1-4) ---
  final currentStep = 1.obs;
  final isResubmitting = false.obs;

  // Step 1: Hospital details
  final hospitalNameC = TextEditingController();
  final hospitalType = 'Private'.obs;
  final cityC = TextEditingController();
  final addressC = TextEditingController();
  final opdTimingsC = TextEditingController();

  // Step 2 (M6): Manager details
  final managerNameC = TextEditingController();
  final managerEmailC = TextEditingController();
  final managerPhoneC = TextEditingController();
  final managerDesignation = 'Medical Superintendent'.obs;
  final isAuthorizedConfirmed = false.obs;

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

  // Step 3 (M7): Logo & verification documents
  final logoFileName = ''.obs;
  final logoFileSize = ''.obs;
  final logoUrl = ''.obs;
  final logoBase64 = ''.obs;

  final licenseDocName = ''.obs;
  final licenseDocSize = ''.obs;
  final licenseDocUrl = ''.obs;
  final documentBase64 = ''.obs;
  final documentType = 'application/pdf'.obs;

  final certificateDocName = ''.obs;
  final certificateDocSize = ''.obs;
  final certificateDocUrl = ''.obs;
  final certificateBase64 = ''.obs;
  final certificateDataType = 'application/pdf'.obs;

  // Step 4 (M8): Review & submit
  final isTermsConfirmed = false.obs;

  // --- Current Hospital Status (M9 Rejected / M11 Suspended) ---
  final currentHospital = Rxn<HospitalModel>();

  // --- Manage Departments (M10) ---
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
    prefillManagerFromAuth();
    ever(currentHospital, (hosp) {
      if (hosp != null && hosp.status.trim().toLowerCase() == 'pending') {
        startStatusPolling();
      }
    });
  }

  /// Pre-fills the manager contact fields from the logged-in account.
  void prefillManagerFromAuth() {
    ApiService.getUserData().then((user) {
      if (user == null) return;
      final email = user['email']?.toString() ?? '';
      final name = user['name']?.toString() ?? '';
      if (email.isNotEmpty && managerEmailC.text.isEmpty) {
        managerEmailC.text = email;
      }
      if (name.isNotEmpty && managerNameC.text.isEmpty) {
        managerNameC.text = name;
      }
    });
  }

  /// Called on logout so the next account never sees the previous manager's data.
  void resetSession() {
    stopStatusPolling();
    currentHospital.value = null;
    isResubmitting.value = false;
    hospitalNameC.clear();
    cityC.clear();
    addressC.clear();
    opdTimingsC.clear();
    managerNameC.clear();
    managerEmailC.clear();
    managerPhoneC.clear();
  }

  @override
  void onClose() {
    stopStatusPolling();
    hospitalNameC.dispose();
    cityC.dispose();
    addressC.dispose();
    opdTimingsC.dispose();
    managerNameC.dispose();
    managerEmailC.dispose();
    managerPhoneC.dispose();
    super.onClose();
  }

  // --- Live Status Polling (Pending -> Approved / Rejected) ---
  // void startStatusPolling() {
  // stopStatusPolling();
  // _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
  // await _checkStatusSilently();
  // });
  // }

  // void stopStatusPolling() {
  // _statusTimer?.cancel();
  // _statusTimer = null;
  // }

  // Future<void> _checkStatusSilently() async {
  // try {
  // final response = await ApiService.getMyHospital();
  // final rawHospital = response['hospital'] ?? response['data'];
  // if (response['success'] == true && rawHospital is Map) {
  // final hosp = HospitalModel.fromMap(
  // Map<String, dynamic>.from(rawHospital),
  // );
  // final previousStatus = currentHospital.value?.status.trim().toLowerCase();
  // final newStatus = hosp.status.trim().toLowerCase();
  //
  // currentHospital.value = hosp;
  //
  // // Agar status pending se badal kar approved/rejected/suspended ho jaye
  // if (newStatus != 'pending' && newStatus != previousStatus) {
  // stopStatusPolling();
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  // _routeBasedOnHospital(hosp);
  // });
  // }
  // }
  // } catch (_) {
  // // Silent retry on next tick
  // }
  // }

  // void _routeBasedOnHospital(HospitalModel hosp) {
  // final status = hosp.status.trim().toLowerCase();
  // if (status == 'rejected') {
  // isResubmitting.value = true;
  // prefillFromHospital(hosp);
  // Get.offAllNamed(AppRoutes.registrationRejected);
  // } else if (status == 'suspended') {
  // Get.offAllNamed(AppRoutes.hospitalSuspended);
  // } else if (status == 'pending') {
  // Get.offAll(() => const PendingApprovalView());
  // startStatusPolling();
  // } else if (status == 'approved') {
  // Get.offAllNamed(AppRoutes.managerDashboard);
  // } else {
  // Get.offAllNamed(AppRoutes.registrationForm);
  // }
  // }

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

  void attachLogo({
    required String name,
    required String size,
    String url = '',
    String base64 = '',
  }) {
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
    opdTimingsC.text = hospital.opdTimings.isNotEmpty
        ? hospital.opdTimings
        : '9:00 AM - 8:00 PM';

    if (hospital.managerName.isNotEmpty) {
      managerNameC.text = hospital.managerName;
    }
    if (hospital.managerEmail.isNotEmpty) {
      managerEmailC.text = hospital.managerEmail;
    }
    if (hospital.managerPhone.isNotEmpty) {
      managerPhoneC.text = hospital.managerPhone;
    }
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
    if (isLoading.value) return;
    if (!isTermsConfirmed.value || !isAuthorizedConfirmed.value) {
      Get.snackbar(
        'Confirmation required',
        'Confirm that you are authorized and that the submitted information is accurate.',
      );
      return;
    }

    final name = hospitalNameC.text.trim();
    final city = cityC.text.trim();
    final address = addressC.text.trim();
    final managerName = managerNameC.text.trim();
    final managerEmail = managerEmailC.text.trim();
    if (name.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        managerName.isEmpty ||
        managerEmail.isEmpty ||
        !GetUtils.isEmail(managerEmail)) {
      Get.snackbar(
        'Missing information',
        'Please complete hospital name, city, address, manager name and a valid manager email.',
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final payload = <String, dynamic>{
        'name': name,
        'hospital_type': hospitalType.value,
        'city': city,
        'address': address,
        'phone': managerPhoneC.text.trim(),
        'email': managerEmail,
        'opd_timings': opdTimingsC.text.trim(),
        'logo_url': logoUrl.value,
        'manager_name': managerName,
        'manager_email': managerEmail,
        'manager_phone': managerPhoneC.text.trim(),
        'manager_designation': managerDesignation.value,
        'license_doc_name': licenseDocName.value,
        'license_doc_size': licenseDocSize.value,
        'license_doc_url': licenseDocUrl.value,
        'certificate_doc_name': certificateDocName.value,
        'certificate_doc_size': certificateDocSize.value,
        'certificate_doc_url': certificateDocUrl.value,
        // Binary documents (stored as BYTEA by the backend)
        'logo_base64': logoBase64.value.isNotEmpty ? logoBase64.value : null,
        'logo_name': logoFileName.value.isNotEmpty ? logoFileName.value : null,
        'document_base64': documentBase64.value.isNotEmpty
            ? documentBase64.value
            : null,
        'document_name': licenseDocName.value.isNotEmpty
            ? licenseDocName.value
            : null,
        'document_type': documentType.value,
        'certificate_base64': certificateBase64.value.isNotEmpty
            ? certificateBase64.value
            : null,
        'certificate_data_type': certificateDataType.value,
      };

      final response = isResubmitting.value
          ? await ApiService.resubmitHospital(payload)
          : await ApiService.registerHospital(payload);
      if (response['success'] != true) {
        errorMessage.value =
            (response['message'] ?? 'Registration submission failed')
                .toString();
        Get.snackbar('Submission failed', errorMessage.value);
        return;
      }

      final hospital = response['hospital'] ?? response['data'];
      if (hospital is Map) {
        currentHospital.value = HospitalModel.fromMap(
          Map<String, dynamic>.from(hospital),
        );
      }
      isResubmitting.value = false;
      Get.offAllNamed(AppRoutes.pendingApproval);
      startStatusPolling();
    } catch (e) {
      errorMessage.value =
          'Unable to submit registration. Check your connection and try again.';
      Get.snackbar('Network error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyHospital({bool routeByStatus = false}) async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMyHospital();
      final rawHospital = response['hospital'] ?? response['data'];

      if (response['success'] == true && rawHospital is Map) {
        final hosp = HospitalModel.fromMap(
          Map<String, dynamic>.from(rawHospital),
        );
        currentHospital.value = hosp;
        if (routeByStatus) {
          _routeBasedOnHospital(hosp);
        }
      } else if (routeByStatus) {
        currentHospital.value = null;
        currentStep.value = 1;
        Get.offAllNamed(AppRoutes.registrationForm);
      }
    } catch (_) {
      // Keep current state if offline
    } finally {
      isLoading.value = false;
    }
  }

  Future loadDepartments() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getDepartments(
        search: departmentSearchQuery.value,
      );
      if (response['success'] == true && response['departments'] is List) {
        final list = (response['departments'] as List)
            .whereType()
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

  Future toggleDepartment(DepartmentModel dept, bool value) async {
    final index = departments.indexWhere(
      (d) => d.departmentId == dept.departmentId,
    );
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
      if (index != -1) departments[index] = dept;
      Get.snackbar('Network error', 'Department status could not be updated.');
    }
  }

  Future addDepartment({
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
        Get.snackbar(
          'Error',
          response['message'] ?? 'Department could not be created',
        );
      }
    } catch (_) {
      Get.snackbar(
        'Network error',
        'Department could not be created. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
