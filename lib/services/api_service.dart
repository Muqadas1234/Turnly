import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Emulator uses 10.0.2.2, physical devices/web use localhost
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Token storage helpers
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // User session cache
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

  // Clear stored credentials
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Headers builder
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

  // Signup request
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
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

  // Verify OTP code
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'otp_code': otpCode,
      }),
    );
    return _decode(response);
  }

  // Request new OTP code
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    return _decode(response);
  }

  // Login request
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );
    return _decode(response);
  }

  // Fetch current user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
    );
    return _decode(response);
  }

  // Update profile details
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
  }) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
      body: jsonEncode({
        if (name != null) 'name': name,
      }),
    );
    return _decode(response);
  }

  // ================= ADMIN ENDPOINTS =================

  // Fetch hospital registrations with status filter ('pending', 'approved', 'suspended')
  static Future<Map<String, dynamic>> getAdminHospitals({String? status}) async {
    final headers = await _authHeaders();
    String url = '$baseUrl/admin/hospitals';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    return _decode(response);
  }

  // Approve a hospital registration
  static Future<Map<String, dynamic>> approveHospital(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/hospitals/$hospitalId/approve'),
      headers: headers,
    );
    return _decode(response);
  }

  // Reject a hospital registration with an optional rejection note
  static Future<Map<String, dynamic>> rejectHospital(int hospitalId, {String? rejectionNote}) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/hospitals/$hospitalId/reject'),
      headers: headers,
      body: jsonEncode({'rejectionNote': rejectionNote}),
    );
    return _decode(response);
  }

  // Suspend an approved hospital
  static Future<Map<String, dynamic>> suspendHospital(int hospitalId) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/hospitals/$hospitalId/suspend'),
      headers: headers,
    );
    return _decode(response);
  }

  // Fetch overall platform statistics
  static Future<Map<String, dynamic>> getPlatformStats() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
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