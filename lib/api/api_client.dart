import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://schoolsmirror.com';
  static String? _token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
    required String deviceId,
    bool isBiometric = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/flutter_login.php'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'login': login,
        'password': password,
        'device_id': deviceId,
        'is_biometric': isBiometric ? '1' : '0',
      },
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (data['success'] == true) {
      final token = data['data']['token'] as String;
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', data['data']['user_id']);
      await prefs.setInt('portaladmin_id', data['data']['portaladmin_id']);
      await prefs.setString('role', data['data']['role'] ?? '');
      await prefs.setString('fullname', data['data']['fullname'] ?? '');
    }
    return data;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}