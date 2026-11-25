import 'package:flutter/foundation.dart';
class ApiEndpoints {
  // Load environment configuration with production as the default
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: true);
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (isProduction) {
      return 'https://turnly-backend.vercel.app/api';
    }

    // Localhost fallback
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

  // Patient Endpoints
  static String get patientHospitals => '$baseUrl/patient/hospitals';
  static String get patientActiveToken => '$baseUrl/patient/active-token';
  static String patientHospitalDetail(int id) => '$baseUrl/patient/hospitals/$id';



  // Token Booking & Queue Preview Endpoints
  static String get bookTokenUrl => '$baseUrl/patient/tokens/book';
  static String doctorQueueStatus(int id) => '$baseUrl/patient/doctors/$id/queue-status';

  // Forgot & Reset Password Endpoints
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';

  // Change Password Endpoint
  static String get changePasswordUrl => '$baseUrl/auth/change-password';
}
