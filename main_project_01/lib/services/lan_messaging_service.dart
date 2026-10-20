
import 'dart:convert';
import 'package:http/http.dart' as http;

class LanMessagingService {
  static const String baseUrl =
      'http://192.168.1.33:3000';

  static Future<String> sendMessage(String message) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/lan-message'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
      }),
    )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception(
        'LAN request failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    return data['reply'] as String;
  }
}
