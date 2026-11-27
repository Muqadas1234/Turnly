import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: true);
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (isProduction) {
      return 'https://turnly-backend.vercel.app/api';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }
  static String get signupUrl => '$baseUrl/auth/signup';
  static String get verifyOtpUrl => '$baseUrl/auth/verify-otp';
  static String get resendOtpUrl => '$baseUrl/auth/resend-otp';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get profileUrl => '$baseUrl/auth/profile';

  static String get hospitalsUrl => '$baseUrl/hospitals';
  static String hospitalDetail(int id) => '$baseUrl/hospitals/$id';
  static String hospitalDepartments(int id) => '$baseUrl/hospitals/$id/departments';
  static String hospitalDoctors(int id) => '$baseUrl/hospitals/$id/doctors';
  static String get citiesUrl => '$baseUrl/hospitals/cities';

  static String get registerHospitalUrl => '$baseUrl/hospitals/register';
  static String get resubmitHospitalUrl => '$baseUrl/hospitals/resubmit';
  static String get myHospitalUrl => '$baseUrl/hospitals/my-hospital';

  static String get departmentsUrl => '$baseUrl/departments';
  static String toggleDepartmentUrl(String id) => '$baseUrl/departments/$id/toggle';
  static String get doctorsUrl => '$baseUrl/doctors';
  static String get tokensUrl => '$baseUrl/tokens';
  static String get fcmTokenUrl => '$baseUrl/auth/fcm-token';
  static String get myTokensUrl => '$baseUrl/tokens/my';
  static String tokenDetail(int id) => '$baseUrl/tokens/$id';
  static String cancelToken(int id) => '$baseUrl/tokens/$id/cancel';
  static String get familyUrl => '$baseUrl/family';
  static String get queueStatsUrl => '$baseUrl/queue/stats';
  static String queueOverview(int doctorId) => '$baseUrl/queue/$doctorId';
  static String get adminHospitals => '$baseUrl/admin/hospitals';
  static String adminHospitalDetail(int id) => '$baseUrl/admin/hospitals/$id';
  static String adminApproveHospital(int id) => '$baseUrl/admin/hospitals/$id/approve';
  static String adminRejectHospital(int id) => '$baseUrl/admin/hospitals/$id/reject';
  static String adminSuspendHospital(int id) => '$baseUrl/admin/hospitals/$id/suspend';
  static String get adminStats => '$baseUrl/admin/stats';
  static String get notificationsUrl => '$baseUrl/notifications';
  static String get notificationsReadAllUrl => '$baseUrl/notifications/read-all';
  static String notificationRead(int id) => '$baseUrl/notifications/$id/read';
  static String adminDeleteHospital(int id) => '$baseUrl/admin/hospitals/$id';
  static String get adminManagers => '$baseUrl/admin/managers';
  static String get adminUsers => '$baseUrl/admin/users';
  static String get patientHospitals => '$baseUrl/patient/hospitals';
  static String get patientActiveToken => '$baseUrl/patient/active-token';
  static String patientHospitalDetail(int id) => '$baseUrl/patient/hospitals/$id';
  static String get bookTokenUrl => '$baseUrl/patient/tokens/book';
  static String doctorQueueStatus(int id) => '$baseUrl/patient/doctors/$id/queue-status';
  static String hospitalDocumentUrl(int id) => '$baseUrl/hospitals/$id/document';
  static String hospitalCertificateUrl(int id) => '$baseUrl/hospitals/$id/certificate';
  static String hospitalLogoUrl(int id) => '$baseUrl/hospitals/$id/logo';
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';
  static String get changePasswordUrl => '$baseUrl/auth/change-password';
}
