import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator
  static const String baseUrl = 'http://192.168.1.18:5000/api';

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('POST Request: $url');
    print('Body: $body');
    
    // Get token if available
    String? token;
    try {
        // Avoiding circular dependency if ApiService is used in AuthController
        // So we might need to rely on the caller to pass it or use SharedPreferences directly here.
        // But importing SharedPreferences here is fine.
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
    } catch (e) {
        print('Error fetching token: $e');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
        headers['Authorization'] = 'Bearer $token'; // Though login/signup usually don't need it.
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    print('POST Response (${response.statusCode}): ${response.body}');
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('GET Request: $url');

    String? token;
    try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
    } catch (e) {
        print('Error fetching token: $e');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
        headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      url,
      headers: headers,
    );
    print('GET Response (${response.statusCode}): ${response.body}');
    return response;
  }

  static Future<dynamic> getJson(String endpoint) async {
    final response = await get(endpoint);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('PATCH Request: $url');
    print('Body: $body');

    String? token;
    try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
    } catch (e) {
        print('Error fetching token: $e');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
        headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    print('PATCH Response (${response.statusCode}): ${response.body}');
    return response;
  }
  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('DELETE Request: $url');

    String? token;
    try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
    } catch (e) {
        print('Error fetching token: $e');
    }

    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
        headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(
      url,
      headers: headers,
    );
    print('DELETE Response (${response.statusCode}): ${response.body}');
    return response;
  }
}
