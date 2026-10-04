import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/settings_provider.dart';
import '../core/l10n.dart';

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

/// Called with the full text received so far while an answer streams in.
typedef PartialCallback = void Function(String textSoFar);

/// Sends prompts to the LLM provider configured in Settings.
///
/// Answers are streamed (server-sent events), so long reports from slow
/// reasoning models show up progressively and are not cut off by a fixed
/// request timeout. Only used when the user explicitly asks for an AI answer.
class AiService {
  static const String systemPrompt =
      'You are an expert Vedic (Jyotish) astrologer. Base every statement on the chart data provided, '
      'which was calculated with the Swiss Ephemeris in the sidereal zodiac (Lahiri ayanamsa). '
      'Do not recalculate positions. Respond in Markdown.';

  /// Longest silence allowed while waiting for (more of) an answer. Reasoning
  /// models can think for several minutes before the first token.
  static Duration idleTimeout = const Duration(minutes: 5);

  /// HTTP client factory (replaced in tests).
  static http.Client Function() clientFactory = http.Client.new;

  /// Anthropic models that accept server-side refusal fallbacks (`fallbacks: "default"`).
  static const Set<String> _anthropicFallbackModels = {
    'claude-fable-5-1', 'claude-opus-5-5', 'claude-opus-5', 'claude-sonnet-5-5',
  };

  static Future<String> interpret(SettingsState config, String prompt, {PartialCallback? onPartial}) =>
      chat(config, [ChatMessage.user(prompt)], onPartial: onPartial);

  static Future<String> chat(SettingsState config, List<ChatMessage> messages, {PartialCallback? onPartial}) async {
    _checkConfig(config);
    final String system = '$systemPrompt Provide the response in ${config.aiLanguage}.';
    final client = clientFactory();
    try {
      final String text = config.llmProvider == 'Anthropic'
          ? await _anthropic(client, config, system, messages, onPartial)
          : await _openAiCompatible(client, config, system, messages, onPartial);
      if (text.trim().isEmpty) {
        throw AiException(tr('The AI provider returned an empty response. Check the model name in Settings > AI.', 'AI प्रदाता ने खाली उत्तर दिया। सेटिंग्स > AI में मॉडल का नाम जाँचें।'));
      }
      return text;
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw AiException(tr('The AI provider stopped responding. Please try again, or pick a faster model in Settings > AI.', 'AI प्रदाता ने उत्तर देना बंद कर दिया (stopped responding)। फिर से कोशिश करें, या सेटिंग्स > AI में तेज़ मॉडल चुनें।'));
    } on FormatException catch (e) {
      throw AiException('${tr('Unexpected response from the AI provider', 'AI प्रदाता से अप्रत्याशित उत्तर')}: ${e.message}');
    } catch (e) {
      throw AiException('${tr('Could not reach the AI provider. Check your internet connection and the API endpoint.', 'AI प्रदाता तक नहीं पहुँच सके। इंटरनेट कनेक्शन और API एंडपॉइंट जाँचें।')}\n($e)');
    } finally {
      client.close();
    }
  }

  static void _checkConfig(SettingsState config) {
    if (config.llmProvider != 'Custom' && config.apiKey.trim().isEmpty) {
      throw AiException(tr('API key is not configured. Please enter it in Settings > AI.', 'API कुंजी सेट नहीं है। कृपया सेटिंग्स > AI में दर्ज करें।'));
    }
    if (config.apiEndpoint.trim().isEmpty) {
      throw AiException(tr('API endpoint is not configured. Please set it in Settings > AI.', 'API एंडपॉइंट सेट नहीं है। कृपया सेटिंग्स > AI में सेट करें।'));
    }
    if (config.modelName.trim().isEmpty) {
      throw AiException(tr('No model selected. Please choose one in Settings > AI.', 'कोई मॉडल चुना नहीं गया। कृपया सेटिंग्स > AI में चुनें।'));
    }
    if (Uri.tryParse(config.apiEndpoint.trim())?.hasScheme != true) {
      throw AiException(tr('The API endpoint is not a valid URL.', 'API एंडपॉइंट सही URL नहीं है।'));
    }
  }

  static Map<String, String> _openAiHeaders(SettingsState config) => {
        'Content-Type': 'application/json',
        if (config.apiKey.trim().isNotEmpty) 'Authorization': 'Bearer ${config.apiKey.trim()}',
      };

  static Map<String, String> _anthropicHeaders(SettingsState config, {bool fallback = false}) => {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey.trim(),
        'anthropic-version': '2023-06-01',
        if (fallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
      };

  static Future<String> _openAiCompatible(http.Client client, SettingsState config, String system,
      List<ChatMessage> messages, PartialCallback? onPartial) async {
    final request = http.Request('POST', Uri.parse(config.apiEndpoint.trim()))
      ..headers.addAll({..._openAiHeaders(config), 'Accept': 'text/event-stream'})
      ..body = jsonEncode({
        'model': config.modelName.trim(),
        'stream': true,
        'messages': [
          {'role': 'system', 'content': system},
          for (final m in messages) {'role': m.role, 'content': m.content},
        ],
      });

    final response = await client.send(request).timeout(idleTimeout);
    await _throwIfError(response);

    if (!_isEventStream(response)) {
      // Server ignored "stream": parse the regular JSON body.
      final data = _decodeJson(await _readBody(response));
      return _openAiMessageText(data);
    }

    final buffer = StringBuffer();
    String? finishReason;
    await for (final event in _sseEvents(response)) {
      if (event.data == '[DONE]') break;
      final json = _tryJson(event.data);
      if (json == null) continue;
      if (json['error'] != null) throw AiException('API error: ${_errorMessage(json)}');
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final choice = choices.first;
      final delta = choice is Map ? (choice['delta'] ?? choice['message']) : null;
      final content = delta is Map ? delta['content'] : null;
      if (content is String && content.isNotEmpty) {
        buffer.write(content);
        onPartial?.call(buffer.toString());
      }
      if (choice is Map && choice['finish_reason'] is String) finishReason = choice['finish_reason'];
    }
    if (buffer.isEmpty && finishReason == 'content_filter') {
      throw AiException(tr('The provider blocked this response (content filter).', 'प्रदाता ने यह उत्तर रोक दिया (कंटेंट फ़िल्टर)।'));
    }
    return buffer.toString();
  }

  static String _openAiMessageText(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final content = choices[0]['message']?['content'];
      if (content is String) return content;
      if (content is List) {
        return content.whereType<Map>().map((p) => p['text']).whereType<String>().join();
      }
    }
    return '';
  }

  static Future<String> _anthropic(http.Client client, SettingsState config, String system,
      List<ChatMessage> messages, PartialCallback? onPartial) async {
    final bool fallback = _anthropicFallbackModels.contains(config.modelName.trim());
    final request = http.Request('POST', Uri.parse(config.apiEndpoint.trim()))
      ..headers.addAll(_anthropicHeaders(config, fallback: fallback))
      ..body = jsonEncode({
        'model': config.modelName.trim(),
        'max_tokens': 16000,
        'stream': true,
        'system': system,
        'messages': [
          for (final m in messages) {'role': m.role, 'content': m.content},
        ],
        if (fallback) 'fallbacks': 'default',
      });

    final response = await client.send(request).timeout(idleTimeout);
    await _throwIfError(response);

    if (!_isEventStream(response)) {
      final data = _decodeJson(await _readBody(response));
      if (data['stop_reason'] == 'refusal') throw AiException(tr('The model declined to answer this request.', 'मॉडल ने इस अनुरोध का उत्तर देने से मना कर दिया।'));
      final content = data['content'];
      return content is List
          ? content.where((b) => b is Map && b['type'] == 'text').map((b) => b['text'] as String).join('\n')
          : '';
    }

    final buffer = StringBuffer();
    await for (final event in _sseEvents(response)) {
      final json = _tryJson(event.data);
      if (json == null) continue;
      switch (json['type']) {
        case 'content_block_delta':
          final delta = json['delta'];
          if (delta is Map && delta['type'] == 'text_delta' && delta['text'] is String) {
            buffer.write(delta['text']);
            onPartial?.call(buffer.toString());
          }
        case 'message_delta':
          if (json['delta'] is Map && json['delta']['stop_reason'] == 'refusal' && buffer.isEmpty) {
            throw AiException(tr('The model declined to answer this request.', 'मॉडल ने इस अनुरोध का उत्तर देने से मना कर दिया।'));
          }
        case 'error':
          throw AiException('API error: ${_errorMessage(json)}');
      }
    }
    return buffer.toString();
  }

  static bool _isEventStream(http.StreamedResponse r) =>
      (r.headers['content-type'] ?? '').toLowerCase().contains('text/event-stream');

  static Future<String> _readBody(http.StreamedResponse r) async =>
      utf8.decode(await r.stream.timeout(idleTimeout).expand((c) => c).toList());

  static Future<void> _throwIfError(http.StreamedResponse response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = await _readBody(response);
    String detail = body.trim();
    final json = _tryJson(body);
    if (json != null) {
      detail = _errorMessage(json);
    } else {
      try {
        final list = jsonDecode(body);
        if (list is List && list.isNotEmpty && list.first is Map) detail = _errorMessage(Map<String, dynamic>.from(list.first));
      } catch (_) {}
    }
    if (detail.length > 400) detail = '${detail.substring(0, 400)}…';
    final hint = switch (response.statusCode) {
      401 || 403 => tr(' (check the API key)', ' (API कुंजी जाँचें)'),
      404 => tr(' (check the endpoint URL and the model name)', ' (एंडपॉइंट URL और मॉडल का नाम जाँचें)'),
      429 => tr(' (rate limit or no credits left on this account)', ' (सीमा पार हो गई या खाते में क्रेडिट नहीं बचे)'),
      _ => '',
    };
    throw AiException('API error ${response.statusCode}$hint: $detail');
  }

  static String _errorMessage(Map<String, dynamic> json) {
    final e = json['error'];
    if (e is Map && e['message'] != null) return e['message'].toString();
    if (e is String) return e;
    return (json['message'] ?? json['detail'] ?? jsonEncode(json)).toString();
  }

  static Map<String, dynamic>? _tryJson(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _decodeJson(String body) {
    final v = _tryJson(body);
    if (v == null) throw AiException(tr('Unexpected response from the AI provider.', 'AI प्रदाता से अप्रत्याशित उत्तर।'));
    return v;
  }

  /// Parses a server-sent event stream into events, applying [idleTimeout]
  /// between chunks (keep-alive comments also count as activity).
  static Stream<({String? event, String data})> _sseEvents(http.StreamedResponse response) async* {
    final lines = response.stream.timeout(idleTimeout).transform(utf8.decoder).transform(const LineSplitter());
    String? event;
    final data = StringBuffer();
    await for (final line in lines) {
      if (line.isEmpty) {
        if (data.isNotEmpty) yield (event: event, data: data.toString());
        event = null;
        data.clear();
        continue;
      }
      if (line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') event = value;
      if (field == 'data') {
        if (data.isNotEmpty) data.write('\n');
        data.write(value);
      }
    }
    if (data.isNotEmpty) yield (event: event, data: data.toString());
  }

  /// Sends a tiny request to verify endpoint, key and model.
  static Future<void> testConnection(SettingsState config) async {
    await chat(config, [const ChatMessage.user('Reply with the single word: OK')]);
  }

  /// Model ids offered by the provider's `/models` endpoint, newest first,
  /// with embedding/image/audio models filtered out.
  static Future<List<String>> listModels(SettingsState config) async {
    if (config.llmProvider != 'Custom' && config.apiKey.trim().isEmpty) {
      throw AiException(tr('Enter your API key first to load the models available to your account.', 'अपने खाते के मॉडल देखने के लिए पहले API कुंजी दर्ज करें।'));
    }
    final uri = modelsUri(config.llmProvider, config.apiEndpoint.trim());
    if (uri == null) throw AiException(tr('Cannot work out the models URL from the API endpoint.', 'API एंडपॉइंट से मॉडल सूची का URL नहीं बन सका।'));
    final client = clientFactory();
    try {
      final headers = config.llmProvider == 'Anthropic' ? _anthropicHeaders(config) : _openAiHeaders(config);
      final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        final json = _tryJson(utf8.decode(response.bodyBytes));
        throw AiException('${tr('Could not load models', 'मॉडल लोड नहीं हो सके')} (HTTP ${response.statusCode})'
            '${json != null ? ': ${_errorMessage(json)}' : ''}');
      }
      final json = _decodeJson(utf8.decode(response.bodyBytes));
      final list = json['data'] ?? json['models'];
      if (list is! List) return const [];
      final entries = <(String, num)>[];
      for (int i = 0; i < list.length; i++) {
        final m = list[i];
        String? id = m is Map ? (m['id'] ?? m['name'])?.toString() : m?.toString();
        if (id == null || id.isEmpty) continue;
        if (id.startsWith('models/')) id = id.substring(7);
        if (!isChatModel(id)) continue;
        final created = m is Map ? m['created'] : null;
        // Keep the provider's order when it has no timestamps (Anthropic lists newest first).
        entries.add((id, created is num ? created : -i));
      }
      entries.sort((a, b) => b.$2.compareTo(a.$2));
      return entries.map((e) => e.$1).toSet().toList();
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw AiException(tr('The provider did not answer in time while loading models.', 'मॉडल लोड करते समय प्रदाता ने समय पर उत्तर नहीं दिया।'));
    } catch (e) {
      throw AiException('${tr('Could not load models', 'मॉडल लोड नहीं हो सके')}: $e');
    } finally {
      client.close();
    }
  }

  /// `/models` URL derived from the chat endpoint.
  static Uri? modelsUri(String provider, String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme) return null;
    var path = uri.path;
    for (final suffix in ['/chat/completions', '/messages', '/completions', '/responses']) {
      if (path.endsWith(suffix)) {
        path = path.substring(0, path.length - suffix.length);
        break;
      }
    }
    return uri.replace(path: '$path/models', queryParameters: provider == 'Anthropic' ? {'limit': '1000'} : null);
  }

  static final RegExp _nonChat = RegExp(
      r'embed|tts|whisper|transcri|dall-e|image|imagen|imagine|vision-preview|moderation|audio|realtime|speech|'
      r'voice|video|veo|sora|davinci|babbage|aqa|rerank|search-preview|computer-use|-live',
      caseSensitive: false);

  static bool isChatModel(String id) => !_nonChat.hasMatch(id);
}
