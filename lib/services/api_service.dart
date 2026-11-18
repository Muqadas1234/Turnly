import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnly/services/api_endpoints.dart';

class ApiService {
  // token storage helpers
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
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
}
