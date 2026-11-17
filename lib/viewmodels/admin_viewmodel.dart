import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class AdminViewModel extends GetxController {
  final isLoading = false.obs;
  final selectedTab = 0.obs; // 0 = Approvals, 1 = Stats, 2 = Hospitals, 3 = Profile

  // Filter chips: 'pending', 'approved', 'suspended'
  final selectedFilter = 'pending'.obs;

  final pendingCount = 0.obs;
  final approvedCount = 0.obs;
  final suspendedCount = 0.obs;

  final hospitals = <Map<String, dynamic>>[].obs;
  final approvedHospitals = <Map<String, dynamic>>[].obs;
  final platformStats = <String, dynamic>{}.obs;

  int _filterRequestGen = 0;
  Timer? _poller;

  @override
  void onInit() {
    super.onInit();
    fetchHospitals();
    fetchApprovedHospitals();
    fetchStats();

    // New registrations arrive while the admin has the app open:
    // refresh the Approvals tab quietly every 15 seconds.
    _poller = Timer.periodic(const Duration(seconds: 15), (_) {
      if (selectedTab.value == 0 && !isLoading.value) {
        fetchHospitals(silent: true);
      }
    });
  }

  @override
  void onClose() {
    _poller?.cancel();
    super.onClose();
  }

  int _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  // silent = true: background refresh, no spinner, no error snackbar
  Future<void> fetchHospitals({String? status, bool silent = false}) async {
    final currentGen = silent ? _filterRequestGen : ++_filterRequestGen;
    if (!silent) isLoading.value = true;
    final filter = status ?? selectedFilter.value;

    try {
      final response = await ApiService.getAdminHospitals(status: filter);
      if (currentGen != _filterRequestGen) return;

      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        hospitals.assignAll(list);

        final counts = response['counts'] as Map? ?? {};
        pendingCount.value = _toInt(counts['pending']);
        approvedCount.value = _toInt(counts['approved']);
        suspendedCount.value = _toInt(counts['suspended']);
      }
    } catch (_) {
      if (currentGen != _filterRequestGen) return;
      if (!silent) {
        Get.snackbar(
          'Error',
          'Failed to fetch hospital registrations',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      if (!silent && currentGen == _filterRequestGen) {
        isLoading.value = false;
      }
    }
  }

  Future<void> fetchApprovedHospitals() async {
    try {
      final response = await ApiService.getAdminHospitals(status: 'approved');
      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        approvedHospitals.assignAll(list);
      }
    } catch (_) {}
  }

  void setFilter(String status) {
    selectedFilter.value = status;
    fetchHospitals(status: status);
  }

  Future<bool> approveHospital(int hospitalId) async {
    try {
      final response = await ApiService.approveHospital(hospitalId);
      if (response['success'] == true) {
        Get.snackbar(
          'Approved',
          'Hospital approved successfully',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
        fetchHospitals();
        fetchApprovedHospitals();
        fetchStats();
        return true;
      }
      Get.snackbar(
        'Error',
        response['message'] ?? 'Failed to approve hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to approve hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  Future<bool> rejectHospital(int hospitalId, {String? reason}) async {
    try {
      final response = await ApiService.rejectHospital(hospitalId, rejectionNote: reason);
      if (response['success'] == true) {
        Get.snackbar(
          'Rejected',
          'Hospital registration rejected',
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade800,
        );
        fetchHospitals();
        fetchApprovedHospitals();
        fetchStats();
        return true;
      }
      Get.snackbar(
        'Error',
        response['message'] ?? 'Failed to reject hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to reject hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  Future<bool> suspendHospital(int hospitalId) async {
    try {
      final response = await ApiService.suspendHospital(hospitalId);
      if (response['success'] == true) {
        Get.snackbar(
          'Suspended',
          'Hospital has been suspended',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
        fetchHospitals();
        fetchApprovedHospitals();
        fetchStats();
        return true;
      }
      Get.snackbar(
        'Error',
        response['message'] ?? 'Failed to suspend hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to suspend hospital',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getPlatformStats();
      if (response['success'] == true && response['data'] != null) {
        platformStats.assignAll(Map<String, dynamic>.from(response['data'] as Map));
      }
    } catch (_) {}
  }
}