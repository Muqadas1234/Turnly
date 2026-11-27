import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnly/services/api_endpoints.dart';

class ApiService {
  // token storage helpers
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }



// Register or update the authenticated user's FCM device token
  static Future<Map<String, dynamic>> updateFcmToken({
    required String fcmToken,
  }) async {
    final response = await http.put(
      Uri.parse(ApiEndpoints.fcmTokenUrl),
      headers: await _authHeaders(),
      body: jsonEncode({
        'fcm_token': fcmToken,
        'platform': _platformName(),
      }),
    );

    return _decode(response);
  }

  // Stop push notifications to THIS device (call before the JWT is cleared on logout)
  static Future<Map<String, dynamic>> removeFcmToken({
    required String fcmToken,
  }) async {
    final response = await http.delete(
      Uri.parse(ApiEndpoints.fcmTokenUrl),
      headers: await _authHeaders(),
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return _decode(response);
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }


  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // user session cache
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) return jsonDecode(data);
    return null;
  }

  // clear stored credentials
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // headers builder
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _jsonHeaders() {
    return {'Content-Type': 'application/json'};
  }

  // --- Authentication ---

  // signup request
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.signupUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'fcm_token': fcmToken,
      }),
    );
    return _decode(response);
  }

  // verify otp code
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.verifyOtpUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'otp_code': otpCode,
      }),
    );
    return _decode(response);
  }

  // request new otp code
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.resendOtpUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    return _decode(response);
  }

  // login request
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.loginUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );
    return _decode(response);
  }

  // fetch current user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiEndpoints.profileUrl),
      headers: headers,
    );
    return _decode(response);
  }

  // update profile details
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
  }) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse(ApiEndpoints.profileUrl),
      headers: headers,
      body: jsonEncode({
        if (name != null) 'name': name,
      }),
    );
    return _decode(response);
  }

  // --- Hospital Registration & Status ---

  static Future<Map<String, dynamic>> registerHospital(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiEndpoints.registerHospitalUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> resubmitHospital(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse(ApiEndpoints.resubmitHospitalUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyHospital() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiEndpoints.myHospitalUrl),
      headers: headers,
    );
    return _decode(response);
  }

  // --- Department Management ---

  static Future<Map<String, dynamic>> getDepartments({String? search}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(ApiEndpoints.departmentsUrl).replace(
      queryParameters: (search != null && search.trim().isNotEmpty)
          ? {'search': search.trim()}
          : null,
    );
    final response = await http.get(uri, headers: headers);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiEndpoints.departmentsUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> toggleDepartment(
      String departmentId, {
        bool? isActive,
      }) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse(ApiEndpoints.toggleDepartmentUrl(departmentId)),
      headers: headers,
      body: jsonEncode({
        if (isActive != null) 'is_active': isActive,
      }),
    );
    return _decode(response);
  }

  // --- Admin Endpoints ---

  // Fetch hospitals list for admin
  static Future<Map<String, dynamic>> getAdminHospitals({String? status}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(ApiEndpoints.adminHospitals).replace(
      queryParameters: (status != null && status.isNotEmpty)
          ? {'status': status}
          : null,
    );
    final response = await http.get(uri, headers: headers);
    return _decode(response);
  }

  // Fetch single hospital details for admin
  static Future<Map<String, dynamic>> getAdminHospitalDetail(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiEndpoints.adminHospitalDetail(hospitalId)),
      headers: headers,
    );
    return _decode(response);
  }

  // Approve a hospital registration
  static Future<Map<String, dynamic>> approveHospital(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse(ApiEndpoints.adminApproveHospital(hospitalId)),
      headers: headers,
    );
    return _decode(response);
  }

  // Reject a hospital registration with an optional rejection note
  static Future<Map<String, dynamic>> rejectHospital(int hospitalId, {String? rejectionNote}) async {
    final headers = await _authHeaders();
    final note = (rejectionNote ?? '').trim();
    final response = await http.put(
      Uri.parse(ApiEndpoints.adminRejectHospital(hospitalId)),
      headers: headers,
      body: jsonEncode({
        'rejectionNote': note,
        'rejection_reason': note,
        'reason': note,
      }),
    );
    return _decode(response);
  }
  // Suspend an approved hospital
  static Future<Map<String, dynamic>> suspendHospital(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse(ApiEndpoints.adminSuspendHospital(hospitalId)),
      headers: headers,
    );
    return _decode(response);
  }

  // Fetch overall platform statistics
  static Future<Map<String, dynamic>> getPlatformStats() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiEndpoints.adminStats),
      headers: headers,
    );
    return _decode(response);
  }

  // --- Patient browsing (public approved hospitals) ---
  static Future<Map<String, dynamic>> getHospitals({String? search, String? city, int page = 1}) async {
    final uri = Uri.parse(ApiEndpoints.hospitalsUrl).replace(queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      'page': '$page',
    });
    return _decode(await http.get(uri));
  }

  static Future<Map<String, dynamic>> getHospitalDetail(int hospitalId) async =>
      _decode(await http.get(Uri.parse(ApiEndpoints.hospitalDetail(hospitalId))));

  static Future<Map<String, dynamic>> getHospitalDepartments(int hospitalId) async =>
      _decode(await http.get(Uri.parse(ApiEndpoints.hospitalDepartments(hospitalId))));

  static Future<Map<String, dynamic>> getHospitalDoctors(int hospitalId, {int? departmentId, String? search, String? date}) async {
    final uri = Uri.parse(ApiEndpoints.hospitalDoctors(hospitalId)).replace(queryParameters: {
      if (departmentId != null) 'department_id': '$departmentId',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (date != null && date.isNotEmpty) 'date': date,
    });
    return _decode(await http.get(uri));
  }

  // --- Patient tokens ---
  static Future<Map<String, dynamic>> bookToken({
    required int doctorId,
    String? date,
    int? familyMemberId,
    String? priorityCategory,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.tokensUrl),
      headers: await _authHeaders(),
      body: jsonEncode({
        'doctor_id': doctorId,
        if (date != null && date.isNotEmpty) 'date': date,
        if (familyMemberId != null) 'family_member_id': familyMemberId,
        if (priorityCategory != null && priorityCategory.isNotEmpty) 'priority_category': priorityCategory,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyTokens({String scope = 'active', int limit = 50}) async {
    final uri = Uri.parse(ApiEndpoints.myTokensUrl).replace(queryParameters: {'scope': scope, 'limit': '$limit'});
    return _decode(await http.get(uri, headers: await _authHeaders()));
  }

  static Future<Map<String, dynamic>> getTokenDetail(int tokenId) async =>
      _decode(await http.get(Uri.parse(ApiEndpoints.tokenDetail(tokenId)), headers: await _authHeaders()));

  static Future<Map<String, dynamic>> cancelMyToken(int tokenId) async =>
      _decode(await http.post(Uri.parse(ApiEndpoints.cancelToken(tokenId)), headers: await _authHeaders()));

  static Future<Map<String, dynamic>> getFamilyMembers() async =>
      _decode(await http.get(Uri.parse(ApiEndpoints.familyUrl), headers: await _authHeaders()));

  static Future<Map<String, dynamic>> addFamilyMember({required String name, required String relation, required int age}) async =>
      _decode(await http.post(Uri.parse(ApiEndpoints.familyUrl), headers: await _authHeaders(),
          body: jsonEncode({'name': name, 'relation': relation, 'age': age})));

  // Safe JSON response parser
  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'message': 'Invalid response from server'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Unable to connect to server',
      };
    }
  }

  // Update hospital details / OPD timings (PATCH /api/hospitals/my-hospital)
  static Future<Map<String, dynamic>> updateMyHospital(
      Map<String, dynamic> payload,
      ) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse(ApiEndpoints.myHospitalUrl),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  // Fetch manager dashboard live stats & today's queues (GET /api/queue/stats)
  static Future<Map<String, dynamic>> getManagerDashboard({String? date}) async {
    final headers = await _authHeaders();
    final baseUri = Uri.parse(ApiEndpoints.queueStatsUrl);
    final uri = baseUri.replace(
      queryParameters: (date != null && date.isNotEmpty) ? {'date': date} : null,
    );
    final response = await http.get(uri, headers: headers);
    return _decode(response);
  }
  // --- Notifications (in-app list) ---

  static Future<Map<String, dynamic>> getNotifications({int limit = 50}) async {
    final uri = Uri.parse(ApiEndpoints.notificationsUrl).replace(queryParameters: {'limit': '$limit'});
    return _decode(await http.get(uri, headers: await _authHeaders()));
  }

  static Future<Map<String, dynamic>> markNotificationRead(int id) async =>
      _decode(await http.put(Uri.parse(ApiEndpoints.notificationRead(id)), headers: await _authHeaders()));

  static Future<Map<String, dynamic>> markAllNotificationsRead() async =>
      _decode(await http.put(Uri.parse(ApiEndpoints.notificationsReadAllUrl), headers: await _authHeaders()));

  // ── Added from the A branch ──────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteHospital(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.adminDeleteHospital(hospitalId)),
      headers: headers,
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getAdminManagers({String? status, String? search}) async {
    final headers = await _authHeaders();
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'all') queryParams['status'] = status;
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

    final uri = Uri.parse(ApiEndpoints.adminManagers).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: headers);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getAdminUsers({String? role, String? search}) async {
    final headers = await _authHeaders();
    final queryParams = <String, String>{};
    if (role != null && role.isNotEmpty && role != 'all') queryParams['role'] = role;
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

    final uri = Uri.parse(ApiEndpoints.adminUsers).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: headers);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getPatientHospitals({
    String? city,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (city != null && city.isNotEmpty && city.toLowerCase() != 'all') {
      queryParams['city'] = city;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(ApiEndpoints.patientHospitals).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPatientActiveToken() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.patientActiveToken),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getHospitalDetails(int hospitalId) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.patientHospitalDetail(hospitalId)),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDoctorQueueStatus(int doctorId, {String? date}) async {
    final queryParams = <String, String>{};
    if (date != null && date.trim().isNotEmpty) {
      queryParams['date'] = date.trim();
    }

    final uri = Uri.parse(ApiEndpoints.doctorQueueStatus(doctorId)).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.forgotPasswordUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email.trim()}),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.resetPasswordUrl),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email.trim(),
        'otp_code': otpCode.trim(),
        'new_password': newPassword,
      }),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse(ApiEndpoints.changePasswordUrl),
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return _decode(response);
  }

  /// Legacy booking route (POST /api/patient/tokens/book). The backend still serves it,
  /// but the app books through [bookToken] (POST /api/tokens), the consolidated route.
  static Future<Map<String, dynamic>> bookTokenByHospital({
    required int doctorId,
    required int hospitalId,
    int? departmentId,
    String? patientName,
    String? bookingDate,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.bookTokenUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'doctorId': doctorId,
        'hospitalId': hospitalId,
        if (departmentId != null) 'departmentId': departmentId,
        if (patientName != null && patientName.trim().isNotEmpty) 'patientName': patientName.trim(),
        if (bookingDate != null && bookingDate.trim().isNotEmpty) 'bookingDate': bookingDate.trim(),
      }),
    );
    return jsonDecode(response.body);
  }
}
