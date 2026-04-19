import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const String baseUrl = 'https://focusbraker-api.onrender.com';

class ApiService {
  static Future<String> getDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('device_uuid');

    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString('device_uuid', uuid);
    }

    debugPrint('device_uuid: $uuid');
    return uuid;
  }

  static Future<int?> registerUser() async {
    final deviceUuid = await getDeviceUuid();
    final url = Uri.parse('$baseUrl/api/v1/users');

    debugPrint('registerUser 요청 시작');
    debugPrint('POST url: $url');
    debugPrint('POST body: ${jsonEncode({'device_uuid': deviceUuid})}');

    final response = await http
        .post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_uuid': deviceUuid}),
    )
        .timeout(const Duration(seconds: 30));

    debugPrint('registerUser statusCode: ${response.statusCode}');
    debugPrint('registerUser body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']?['id'];
    }

    throw Exception('회원 등록 실패: ${response.statusCode} ${response.body}');
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
    final url = Uri.parse('$baseUrl/api/v1/sessions');

    debugPrint('startSession 요청 시작');
    debugPrint('POST url: $url');

    final response = await http
        .post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'intensity_level': intensityLevel,
        'hair_enabled': hairEnabled,
        'dust_enabled': dustEnabled,
        'bug_enabled': bugEnabled,
        'fake_noti_enabled': fakeNotiEnabled,
      }),
    )
        .timeout(const Duration(seconds: 10));

    debugPrint('startSession statusCode: ${response.statusCode}');
    debugPrint('startSession body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']?['id'];
    }

    throw Exception('세션 시작 실패: ${response.statusCode} ${response.body}');
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
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/end');

    debugPrint('endSession 요청 시작');
    debugPrint('PATCH url: $url');

    final response = await http
        .patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'events': events}),
    )
        .timeout(const Duration(seconds: 10));

    debugPrint('endSession statusCode: ${response.statusCode}');
    debugPrint('endSession body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']?['report'];
    }

    throw Exception('세션 종료 실패: ${response.statusCode} ${response.body}');
  }

  static Future<Map<String, dynamic>?> getReport(int sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/report');

    debugPrint('getReport 요청 시작');
    debugPrint('GET url: $url');

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    debugPrint('getReport statusCode: ${response.statusCode}');
    debugPrint('getReport body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }

    throw Exception('리포트 조회 실패: ${response.statusCode} ${response.body}');
  }

  static Future<void> abandonSession(int sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/abandon');

    debugPrint('abandonSession 요청 시작');
    debugPrint('PATCH url: $url');

    final response = await http
        .patch(
      url,
      headers: {'Content-Type': 'application/json'},
    )
        .timeout(const Duration(seconds: 10));

    debugPrint('abandonSession statusCode: ${response.statusCode}');
    debugPrint('abandonSession body: ${response.body}');
  }

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
  static Future<void> resetSessionIfExists() async {
    final sessionId = await getSessionId();

    if (sessionId != null) {
      debugPrint('기존 세션 종료 시도: $sessionId');

      try {
        await abandonSession(sessionId); // 서버에 종료 요청
      } catch (e) {
        debugPrint('세션 종료 실패 (무시 가능): $e');
      }

      await clearOverlayEvents(); // 로컬 이벤트 삭제
      await saveSessionId(0); // 세션 초기화 (선택)
    }
  }
  static Future<void> resetAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_uuid');
    await prefs.remove('user_id');
    await prefs.remove('session_id');
    await prefs.remove('overlay_events');
    debugPrint('로컬 데이터 전체 초기화 완료');
  }
  static Future<void> saveOverlayEventsToFile(List<Map<String, dynamic>> events) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/events.json');
    await file.writeAsString(jsonEncode(events));
  }
  static Future<List<Map<String, dynamic>>> getOverlayEventsFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/events.json');

    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final decoded = jsonDecode(content) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}