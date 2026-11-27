import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/routes.dart';
import 'manager_viewmodel.dart';

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

  // helper to get fcm token safely (returns null on unsupported platforms)
  Future<String?> _getFcmToken() => NotificationService.fetchToken();

  /// Ask permission, register this device with the backend and start listening.
  /// Called after every successful login / OTP verification / session restore, for ALL roles.
  Future<void> startPush() async {
    final svc = Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : Get.put(NotificationService(), permanent: true);
    await svc.start(onTokenReady: registerFcmToken);
  }

  Future<void> registerFcmToken(String fcmToken) async {
    try {
      final jwt = await ApiService.getToken();
      if (jwt == null || jwt.isEmpty) {
        debugPrint('FCM registration skipped: user is not logged in');
        return;
      }
      final response = await ApiService.updateFcmToken(fcmToken: fcmToken);
      if (response['success'] == true) {
        debugPrint('FCM token registered successfully');
      } else {
        debugPrint('FCM registration failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('FCM registration error: $e');
    }
  }

  String _normaliseRole(dynamic role) {
    final value = role?.toString().trim().toLowerCase() ?? '';
    if (value == 'hospital_manager' || value == 'hospital manager') return 'manager';
    if (value == 'admin' || value == 'administrator') return 'admin';
    return value; // 'patient', 'manager' or unknown
  }

  /// Single place that persists a successful auth response and routes the user.
  ///  * [enforceRole] – login only: the account must match the role picked on the role screen.
  ///  * [fromOtp]     – OTP verification: new patients see the success screen first.
  Future<void> _completeAuth(
    Map<String, dynamic> response, {
    bool enforceRole = false,
    bool fromOtp = false,
  }) async {
    final user = response['user'];
    final token = response['token'];
    if (user is! Map || token == null) {
      throw const FormatException('The server returned an incomplete response.');
    }
    final actualRole = _normaliseRole(user['role']);

    // Admins have no role card on the role screen, so they are never role-checked.
    if (enforceRole && actualRole != 'admin') {
      final requestedRole = _normaliseRole(selectedRole.value);
      if (requestedRole.isNotEmpty && requestedRole != actualRole) {
        Get.snackbar(
          'Wrong account type',
          'This account is registered as ${actualRole.isEmpty ? 'an unknown role' : actualRole}. Select the matching role to continue.',
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade900,
        );
        return;
      }
    }

    await ApiService.saveToken(token.toString());
    await ApiService.saveUserData(Map<String, dynamic>.from(user));
    _rememberUser(user);

    if (fromOtp && actualRole == 'patient') {
      Get.offAllNamed(AppRoutes.otpSuccess);
    } else {
      await _navigateToHome(actualRole);
    }
    unawaited(startPush());
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_normaliseRole(selectedRole.value) == 'admin') {
      Get.snackbar(
        'Admin account',
        'Admin accounts are created by the platform owner. Please log in with your assigned credentials.',
      );
      return;
    }
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
      final response = await ApiService.verifyOtp(email: email, otpCode: otpCode);

      if (response['success'] == true) {
        // Manager -> hospital-status routing (registration form for a new manager),
        // Patient -> success screen, Admin -> admin panel.
        await _completeAuth(response, fromOtp: true);
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Verification failed. Try again',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
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
        await _completeAuth(response, enforceRole: true);
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
        await _navigateToHome(response['user']['role']);
        unawaited(startPush());
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
    if (Get.isRegistered<ManagerViewModel>()) {
      Get.find<ManagerViewModel>().resetSession();
    }
    // Unregister this device BEFORE the JWT is cleared (the call needs it).
    if (Get.isRegistered<NotificationService>()) {
      try {
        await Get.find<NotificationService>()
            .stopAndUnregister()
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Push cleanup skipped on logout: $e');
      }
    }
    await ApiService.clearAll();
    currentUser.value = null;
    selectedRole.value = '';
    Get.offAllNamed(AppRoutes.roleSelection);
  }

  Future<void> _navigateToHome(dynamic role) async {
    final userRole = _normaliseRole(role);
    if (userRole == 'admin') {
      Get.offAllNamed(AppRoutes.adminPanel);
    } else if (userRole == 'manager') {
      final managerVm = Get.isRegistered<ManagerViewModel>()
          ? Get.find<ManagerViewModel>()
          : Get.put(ManagerViewModel(), permanent: true);
      managerVm.prefillManagerFromAuth();
      // Fresh hospital status decides the exact screen (form / pending / dashboard / ...)
      await managerVm.loadMyHospital(routeByStatus: true);
    } else if (userRole == 'patient') {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.snackbar(
        'Account role error',
        'This account has an unsupported role. Please contact support.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      await ApiService.clearAll();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.roleSelection);
    }
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
  Future<bool> updateProfileName(String newName) async {
    isLoading.value = true;
    try {
      final response = await ApiService.updateProfile(name: newName);

      if (response['success'] == true) {
        // 1. Update the local reactive state with the new name
        final updatedUser = Map<String, dynamic>.from(currentUser.value ?? {});
        updatedUser['name'] = newName;
        currentUser.value = updatedUser;

        // Persist updated user details to local storage
        await ApiService.saveUserData(updatedUser);

        return true;
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Could not update name',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return false;
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
