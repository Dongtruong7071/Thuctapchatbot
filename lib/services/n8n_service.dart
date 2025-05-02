import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String n8nWebhookUrl = dotenv.env['N8N_API_URL']!;

  Future<String> sendDataToN8n(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(n8nWebhookUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['output'] ?? "Không có phản hồi từ n8n.";
      } else {
        return "❌ Lỗi khi gửi dữ liệu: ${response.statusCode}";
      }
    } catch (e) {
      return "❗ Lỗi kết nối: $e";
    }
  }
}
