import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

class AdminViewModel extends GetxController {
  final isLoading = false.obs;
  final selectedTab = 0.obs; // Bottom nav index: 0 = Approvals, 1 = Stats, 2 = Hospitals, 3 = Profile

  // Filter chips: 'pending', 'approved', 'suspended'
  final selectedFilter = 'pending'.obs;

  // Status counts
  final pendingCount = 0.obs;
  final approvedCount = 0.obs;
  final suspendedCount = 0.obs;

  // Filtered hospitals list for Approvals tab
  final hospitals = <Map<String, dynamic>>[].obs;

  // Dedicated list of all approved active hospitals
  final approvedHospitals = <Map<String, dynamic>>[].obs;

  // Platform statistics
  final platformStats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHospitals();
    fetchApprovedHospitals();
    fetchStats();
  }

  // Fetch hospitals filtered by selected status for Approvals tab
  Future<void> fetchHospitals({String? status}) async {
    isLoading.value = true;
    final filter = status ?? selectedFilter.value;

    try {
      final response = await ApiService.getAdminHospitals(status: filter);
      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        hospitals.assignAll(list);

        // Update counts
        final counts = response['counts'] as Map? ?? {};
        pendingCount.value = counts['pending'] ?? 0;
        approvedCount.value = counts['approved'] ?? 0;
        suspendedCount.value = counts['suspended'] ?? 0;
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to fetch hospital registrations',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all approved hospitals for Manage Hospitals tab and Stats preview
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

  // Change filter chip in Approvals tab
  void setFilter(String status) {
    selectedFilter.value = status;
    fetchHospitals(status: status);
  }

  // Approve a hospital
  Future<void> approveHospital(int hospitalId) async {
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
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to approve hospital');
    }
  }

  // Reject a hospital
  Future<void> rejectHospital(int hospitalId, {String? reason}) async {
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
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to reject hospital');
    }
  }

  // Suspend an approved hospital
  Future<void> suspendHospital(int hospitalId) async {
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
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to suspend hospital');
    }
  }

  // Fetch platform statistics
  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getPlatformStats();
      if (response['success'] == true && response['data'] != null) {
        platformStats.assignAll(Map<String, dynamic>.from(response['data'] as Map));
      }
    } catch (_) {}
  }
}
