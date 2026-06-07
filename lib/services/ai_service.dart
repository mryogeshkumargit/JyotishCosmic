import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/settings_provider.dart';

class AiService {
  static Future<String> interpret(SettingsState config, String prompt) async {
    if (config.apiKey.isEmpty) {
      return "Error: API Key is not configured. Please enter it in Settings.";
    }

    try {
      final response = await http.post(
        Uri.parse(config.apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}', // OpenAI, Grok, DeepSeek standard
        },
        body: jsonEncode({
          'model': config.modelName,
          'messages': [
            {'role': 'system', 'content': 'You are an expert Vedic Astrologer providing interpretations. Respond in Markdown format.'},
            {'role': 'user', 'content': '$prompt\n\nProvide the response in ${config.aiLanguage}.'}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "API Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }
}
