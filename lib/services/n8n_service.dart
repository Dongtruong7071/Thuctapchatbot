import 'dart:convert';
import 'package:http/http.dart' as http;

//lt --port 5678 --subdomain n8n-connect-thanhdong
class ApiService {
  static const String n8nWebhookUrl =
      "https://n8n-connect-thanhdong.loca.lt/webhook-test/4a9d5779-7792-4d1a-9b35-4297d3690f69";

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
