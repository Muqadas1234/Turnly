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

  // Persist session and route user to their respective dashboard
  Future<void> _handleAuthSuccess(Map<String, dynamic> response) async {
    final token = response['token'];
    final user = response['user'];

    if (token != null) {
      await ApiService.saveToken(token.toString());
    }
    if (user is Map) {
      final userMap = Map<String, dynamic>.from(user);
      await ApiService.saveUserData(userMap);
      _rememberUser(userMap);
      _navigateToHome(userMap['role']);
    } else {
      _navigateToHome(selectedRole.value);
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
        await _handleAuthSuccess(response);
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Verification failed. Try again',
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
        await _handleAuthSuccess(response);
      } else if (response['requiresVerification'] == true) {
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
    final route = switch (role?.toString().toLowerCase().trim()) {
      'admin' => AppRoutes.adminPanel,
      'manager' => AppRoutes.managerDashboard,
      _ => AppRoutes.home,
    };
    Get.offAllNamed(route);
  }

  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    try {
      final response = await ApiService.forgotPassword(email);
      if (response['success'] == true) {
        Get.snackbar(
          'Code Sent',
          response['message'] ?? 'Reset code sent to your email',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
        // Only navigate if user is still on the forgot-password screen
        if (Get.currentRoute == AppRoutes.forgotPassword) {
          Get.toNamed(AppRoutes.resetPassword, arguments: {'email': email});
        }
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Could not send reset code',
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

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      Get.snackbar(
        'Error',
        'Email is required. Please request a new reset code.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      Get.offNamed(AppRoutes.forgotPassword);
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.resetPassword(
        email: trimmedEmail,
        otpCode: otpCode,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        Get.snackbar(
          'Success',
          'Password reset successfully! Please log in.',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to reset password',
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

  // Edit profile - saves user's new name in backend.

  Future<void> updateProfileName(String newName) async {
    isLoading.value = true;
    try {
      final response = await ApiService.updateProfile(name: newName);

      if (response['success'] == true) {
        // 1. Update the local reactive state with the new name
        final updatedUser = Map<String, dynamic>.from(currentUser.value ?? {});
        updatedUser['name'] = newName;
        currentUser.value = updatedUser;

        //  updated user details to local storage
        await ApiService.saveUserData(updatedUser);

        // Return to profile view and notify the user
        Get.back();
        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Could not update name',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Change password method
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isLoading.value = true;
    try {
      final response = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        return true;
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to change password',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error. Please try again',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
