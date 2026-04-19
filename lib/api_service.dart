import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String baseUrl = 'https://focusbraker-api.onrender.com';

class ApiService {
  static Future<String> getDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('device_uuid');
    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString('device_uuid', uuid);
    }
    return uuid;
  }

  static Future<int?> registerUser() async {
    final deviceUuid = await getDeviceUuid();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_uuid': deviceUuid}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['id'];
    }
    return null;
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<int?> startSession({
    required int userId,
    required int intensityLevel,
    required bool hairEnabled,
    required bool dustEnabled,
    required bool bugEnabled,
    required bool fakeNotiEnabled,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'intensity_level': intensityLevel,
        'hair_enabled': hairEnabled,
        'dust_enabled': dustEnabled,
        'bug_enabled': bugEnabled,
        'fake_noti_enabled': fakeNotiEnabled,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['id'];
    }
    return null;
  }

  static Future<void> saveSessionId(int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_id', sessionId);
  }

  static Future<int?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('session_id');
  }

  static Future<Map<String, dynamic>?> endSession({
    required int sessionId,
    required List<Map<String, dynamic>> events,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/sessions/$sessionId/end'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'events': events}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['report'];
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getReport(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/sessions/$sessionId/report'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    return null;
  }

  static Future<void> abandonSession(int sessionId) async {
    await http.patch(
      Uri.parse('$baseUrl/api/v1/sessions/$sessionId/abandon'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // ---------------------------
  // 오버레이 이벤트 저장/조회/삭제
  // ---------------------------
  static Future<void> saveOverlayEvents(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('overlay_events', jsonEncode(events));
  }

  static Future<List<Map<String, dynamic>>> getOverlayEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('overlay_events');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearOverlayEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('overlay_events');
  }
}