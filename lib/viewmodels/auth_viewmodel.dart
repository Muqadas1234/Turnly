import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_service.dart';
import '../utils/routes.dart';

class AuthViewModel extends GetxController {
  final isLoading = false.obs;
  final isProfileLoading = false.obs;
  final currentUser = Rxn<Map<String, dynamic>>();
  final selectedRole = ''.obs;

  void _rememberUser(dynamic user) {
    if (user is Map) {
      currentUser.value = Map<String, dynamic>.from(user);
    }
  }

  // helper to get fcm token safely
  Future<String?> _getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final fcmToken = await _getFcmToken();

      final response = await ApiService.signup(
        name: name,
        email: email,
        password: password,
        role: selectedRole.value,
        fcmToken: fcmToken,
      );

      if (response['success'] == true) {
        Get.toNamed(AppRoutes.otp, arguments: {'email': email});
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Signup failed',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error. Please try again',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiService.verifyOtp(
        email: email,
        otpCode: otpCode,
      );

      if (response['success'] == true) {
        Get.offAllNamed(AppRoutes.otpSuccess);
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Invalid code',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Verification failed. Try again',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      final response = await ApiService.resendOtp(email: email);
      if (response['success'] == true) {
        Get.snackbar(
          'Sent',
          'Verification code resent',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Could not resend code',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not resend code',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final fcmToken = await _getFcmToken();

      final response = await ApiService.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );

      if (response['success'] == true) {
        await ApiService.saveToken(response['token']);
        await ApiService.saveUserData(response['user']);
        _rememberUser(response['user']);

        final role = response['user']['role'];
        _navigateToHome(role);
      } else {
        if (response['requiresVerification'] == true) {
          Get.snackbar(
            'Verification Required',
            'Please verify your email first',
            backgroundColor: Colors.orange.shade50,
            colorText: Colors.orange.shade800,
          );
          Get.toNamed(AppRoutes.otp, arguments: {'email': email});
        } else {
          Get.snackbar(
            'Error',
            response['message'] ?? 'Invalid credentials',
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade800,
          );
        }
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error. Please try again',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null) {
      Get.offAllNamed(AppRoutes.roleSelection);
      return;
    }

    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        await ApiService.saveUserData(response['user']);
        _rememberUser(response['user']);
        _navigateToHome(response['user']['role']);
      } else {
        await ApiService.clearAll();
        Get.offAllNamed(AppRoutes.roleSelection);
      }
    } catch (_) {
      await ApiService.clearAll();
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }

  Future<void> loadProfile() async {
    isProfileLoading.value = true;
    try {
      final cached = await ApiService.getUserData();
      if (cached != null) currentUser.value = cached;

      final response = await ApiService.getProfile();
      if (response['success'] == true && response['user'] is Map) {
        final user = Map<String, dynamic>.from(response['user'] as Map);
        await ApiService.saveUserData(user);
        currentUser.value = user;
      }
    } catch (_) {
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearAll();
    currentUser.value = null;
    selectedRole.value = '';
    Get.offAllNamed(AppRoutes.roleSelection);
  }

  void _navigateToHome(dynamic role) {
    final userRole = role?.toString().toLowerCase();

    // Check user role and route to corresponding dashboard
    if (userRole == 'admin') {
      Get.offAllNamed(AppRoutes.adminPanel);
    } else if (userRole == 'manager' || userRole == 'hospital_manager') {
      Get.offAllNamed(AppRoutes.managerDashboard);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
