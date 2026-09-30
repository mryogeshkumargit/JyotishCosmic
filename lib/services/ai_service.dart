import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/settings_provider.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  const ChatMessage(this.role, this.content);
  const ChatMessage.user(this.content) : role = 'user';
  const ChatMessage.assistant(this.content) : role = 'assistant';
}

/// Sends prompts to the LLM provider configured in Settings.
///
/// This is the only feature of the app that uses the network, and only when
/// the user explicitly asks for an AI interpretation.
class AiService {
  static const String systemPrompt =
      'You are an expert Vedic (Jyotish) astrologer. Base every statement on the chart data provided, '
      'which was calculated with the Swiss Ephemeris in the sidereal zodiac (Lahiri ayanamsa). '
      'Do not recalculate positions. Respond in Markdown.';

  static const Duration timeout = Duration(minutes: 3);

  /// Anthropic models that accept server-side refusal fallbacks (`fallbacks: "default"`).
  static const Set<String> _anthropicFallbackModels = {
    'claude-fable-5-1', 'claude-opus-5-5', 'claude-opus-5', 'claude-sonnet-5-5',
  };

  static Future<String> interpret(SettingsState config, String prompt) =>
      chat(config, [ChatMessage.user(prompt)]);

  static Future<String> chat(SettingsState config, List<ChatMessage> messages) async {
    final bool needsKey = config.llmProvider != 'Custom';
    if (needsKey && config.apiKey.isEmpty) {
      throw AiException('API key is not configured. Please enter it in Settings > AI Config.');
    }
    if (config.apiEndpoint.trim().isEmpty) {
      throw AiException('API endpoint is not configured. Please set it in Settings > AI Config.');
    }

    final String languageNote = 'Provide the response in ${config.aiLanguage}.';
    final String system = '$systemPrompt $languageNote';

    try {
      if (config.llmProvider == 'Anthropic') {
        return await _anthropic(config, system, messages);
      }
      return await _openAiCompatible(config, system, messages);
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw AiException('The AI provider did not respond in time. Please try again.');
    } catch (e) {
      throw AiException('Connection error: $e');
    }
  }

  static Future<String> _openAiCompatible(SettingsState config, String system, List<ChatMessage> messages) async {
    final response = await http
        .post(
          Uri.parse(config.apiEndpoint.trim()),
          headers: {
            'Content-Type': 'application/json',
            if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
          },
          body: jsonEncode({
            'model': config.modelName,
            'messages': [
              {'role': 'system', 'content': system},
              for (final m in messages) {'role': m.role, 'content': m.content},
            ],
          }),
        )
        .timeout(timeout);

    final data = _decode(response);
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final content = choices[0]['message']?['content'];
      if (content is String && content.isNotEmpty) return content;
    }
    throw AiException('The AI provider returned an empty response.');
  }

  static Future<String> _anthropic(SettingsState config, String system, List<ChatMessage> messages) async {
    final bool fallback = _anthropicFallbackModels.contains(config.modelName);
    final response = await http
        .post(
          Uri.parse(config.apiEndpoint.trim()),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01',
            if (fallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode({
            'model': config.modelName,
            'max_tokens': 16000,
            'system': system,
            'messages': [
              for (final m in messages) {'role': m.role, 'content': m.content},
            ],
            if (fallback) 'fallbacks': 'default',
          }),
        )
        .timeout(timeout);

    final data = _decode(response);
    if (data['stop_reason'] == 'refusal') {
      throw AiException('The model declined to answer this request.');
    }
    final content = data['content'];
    if (content is List) {
      final text = content
          .where((b) => b is Map && b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join('\n');
      if (text.isNotEmpty) return text;
    }
    throw AiException('The AI provider returned an empty response.');
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      String detail = body;
      try {
        final err = jsonDecode(body);
        final e = err is List && err.isNotEmpty ? err.first : err;
        detail = (e['error']?['message'] ?? e['message'] ?? body).toString();
      } catch (_) {}
      throw AiException('API error ${response.statusCode}: $detail');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) throw AiException('Unexpected response from the AI provider.');
    return decoded;
  }

  /// Sends a tiny request to verify endpoint, key and model.
  static Future<void> testConnection(SettingsState config) async {
    await chat(config, [const ChatMessage.user('Reply with the single word: OK')]);
  }
}
