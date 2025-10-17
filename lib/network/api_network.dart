import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl; // e.g. http://192.168.1.10:8080
  ApiClient(this.baseUrl);

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400)
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
