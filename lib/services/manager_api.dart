import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import 'api_service.dart';

/// Manager-side calls (doctors + live queue control).
/// Kept in its own file so it does not touch api_service.dart.
/// Routes (backend): POST /doctors, GET /queue/:doctorId,
/// POST /queue/:doctorId/call-next, POST /queue/tokens/:id/{complete|skip|recall|cancel}
class ManagerApi {
  static Future<Map<String, String>> _headers() async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response r) {
    try {
      final d = jsonDecode(r.body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {'success': false, 'message': 'Unexpected server response (${r.statusCode})'};
  }

  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final r = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}$path'),
        headers: await _headers(),
        body: jsonEncode(body ?? {}),
      );
      return _decode(r);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---- doctors ----
  static Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> payload) =>
      _post('/doctors', payload);

  // ---- queue ----
  static Future<Map<String, dynamic>> getQueueOverview(int doctorId, {String? date}) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/queue/$doctorId')
          .replace(queryParameters: date == null ? null : {'date': date});
      return _decode(await http.get(uri, headers: await _headers()));
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> callNext(int doctorId, {String? date}) =>
      _post('/queue/$doctorId/call-next', date == null ? null : {'date': date});

  static Future<Map<String, dynamic>> completeToken(int tokenId) => _post('/queue/tokens/$tokenId/complete');
  static Future<Map<String, dynamic>> skipToken(int tokenId) => _post('/queue/tokens/$tokenId/skip');
  static Future<Map<String, dynamic>> recallToken(int tokenId) => _post('/queue/tokens/$tokenId/recall');
  static Future<Map<String, dynamic>> cancelToken(int tokenId) => _post('/queue/tokens/$tokenId/cancel');
}