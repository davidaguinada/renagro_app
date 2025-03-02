import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  final String _baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final uri = Uri.parse('$_baseUrl/usuario');
    final payload = {
      "usuario": username,
      "password": password,
    };

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results.containsKey('ERROR')) {
          // User not found scenario
          print('Login failed: ${results['ERROR']}');
          return null;
        } else {
          // Successful login
          final user = results;
          return {
            "UserName": user['UserName'],
            "Role": user['Role'],
          };
        }
      } else {
        print('Login failed: ${response.statusCode} ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }
}
