import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Base URL for Localhost
  // Android Emulator: 10.0.2.2:3000
  // Web / Desktop / iOS: localhost:3000
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Authentication Endpoints
  static String get signupUrl => '$baseUrl/auth/signup';
  static String get verifyOtpUrl => '$baseUrl/auth/verify-otp';
  static String get resendOtpUrl => '$baseUrl/auth/resend-otp';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get profileUrl => '$baseUrl/auth/profile';

  // Admin Endpoints
  static String get adminHospitals => '$baseUrl/admin/hospitals';
  static String adminHospitalDetail(int id) => '$baseUrl/admin/hospitals/$id';
  static String adminApproveHospital(int id) => '$baseUrl/admin/hospitals/$id/approve';
  static String adminRejectHospital(int id) => '$baseUrl/admin/hospitals/$id/reject';
  static String adminSuspendHospital(int id) => '$baseUrl/admin/hospitals/$id/suspend';
  static String get adminStats => '$baseUrl/admin/stats';
}
