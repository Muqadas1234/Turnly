import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Override with --dart-define=API_BASE_URL=http://YOUR_HOST:3000/api
  // Android emulator uses 10.0.2.2 to reach the host computer.
  // A physical phone must use your computer's LAN IP address.
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/+$'), '');
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

  // Hospital Registration & Status Endpoints
  static String get registerHospitalUrl => '$baseUrl/hospitals/register';
  static String get resubmitHospitalUrl => '$baseUrl/hospitals/resubmit';
  static String get myHospitalUrl => '$baseUrl/hospitals/my-hospital';

  // Admin Endpoints
  static String get adminHospitals => '$baseUrl/admin/hospitals';
  static String adminHospitalDetail(int id) => '$baseUrl/admin/hospitals/$id';
  static String adminApproveHospital(int id) => '$baseUrl/admin/hospitals/$id/approve';
  static String adminRejectHospital(int id) => '$baseUrl/admin/hospitals/$id/reject';
  static String adminSuspendHospital(int id) => '$baseUrl/admin/hospitals/$id/suspend';
  static String get adminStats => '$baseUrl/admin/stats';

  // Department Management Endpoints
  static String get departmentsUrl => '$baseUrl/departments';
  static String toggleDepartmentUrl(String id) => '$baseUrl/departments/$id/toggle';
  static String get queueStatsUrl => '$baseUrl/api/queue/stats';
}
