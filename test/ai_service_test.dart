import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_jyotish/providers/settings_provider.dart';
import 'package:mobile_jyotish/services/ai_service.dart';

http.StreamedResponse sse(List<String> chunks, {int status = 200}) => http.StreamedResponse(
      Stream.fromIterable(chunks.map(utf8.encode)),
      status,
      headers: {'content-type': 'text/event-stream; charset=utf-8'},
    );

void main() {
  final grok = SettingsState(
    llmProvider: 'Grok',
    apiEndpoint: LlmProviders.endpoints['Grok']!,
    apiKey: 'xai-test',
    modelName: 'grok-4.7',
  );
  final claude = SettingsState(
    llmProvider: 'Anthropic',
    apiEndpoint: LlmProviders.endpoints['Anthropic']!,
    apiKey: 'sk-ant',
    modelName: 'claude-opus-5-5',
  );

  tearDown(() {
    AiService.clientFactory = http.Client.new;
    AiService.idleTimeout = const Duration(minutes: 5);
  });

  test('streams an OpenAI-compatible (Grok) answer, ignoring reasoning deltas and keep-alives', () async {
    late Map<String, dynamic> sent;
    AiService.clientFactory = () => MockClient.streaming((request, body) async {
          sent = jsonDecode(await body.bytesToString());
          expect(request.headers['Authorization'], 'Bearer xai-test');
          return sse([
            ': keep-alive\n\n',
            'data: {"choices":[{"delta":{"role":"assistant","reasoning_content":"thinking"}}]}\n\n',
            'data: {"choices":[{"delta":{"content":"Namaste"}}]}\n\ndata: {"choices":[{"delta":{"con',
            'tent":", Jupiter is strong."},"finish_reason":"stop"}]}\n\n',
            'data: [DONE]\n\n',
          ]);
        });
    final partials = <String>[];
    final text = await AiService.interpret(grok, 'hello', onPartial: partials.add);
    expect(text, 'Namaste, Jupiter is strong.');
    expect(partials, ['Namaste', 'Namaste, Jupiter is strong.']);
    expect(sent['stream'], true);
    expect(sent['model'], 'grok-4.7');
    expect(sent['messages'][0]['role'], 'system');
    expect(sent.containsKey('temperature'), isFalse);
  });

  test('accepts a plain JSON answer from servers that ignore streaming', () async {
    AiService.clientFactory = () => MockClient((request) async => http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': 'Plain answer'}}
          ]
        }),
        200,
        headers: {'content-type': 'application/json'}));
    expect(await AiService.interpret(grok, 'q'), 'Plain answer');
  });

  test('streams an Anthropic answer', () async {
    AiService.clientFactory = () => MockClient.streaming((request, body) async {
          expect(request.headers['x-api-key'], 'sk-ant');
          final json = jsonDecode(await body.bytesToString());
          expect(json['stream'], true);
          expect(json['fallbacks'], 'default');
          return sse([
            'event: message_start\ndata: {"type":"message_start","message":{}}\n\n',
            'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Om "}}\n\n',
            'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Shanti"}}\n\n',
            'event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}\n\n',
            'event: message_stop\ndata: {"type":"message_stop"}\n\n',
          ]);
        });
    expect(await AiService.interpret(claude, 'q'), 'Om Shanti');
  });

  test('reports provider errors with a hint', () async {
    AiService.clientFactory = () => MockClient((request) async => http.Response(
        jsonEncode({'error': {'message': 'The model grok-4 does not exist'}}), 404,
        headers: {'content-type': 'application/json'}));
    await expectLater(
      AiService.interpret(grok, 'q'),
      throwsA(isA<AiException>().having((e) => e.message, 'message',
          allOf(contains('404'), contains('model name'), contains('grok-4 does not exist')))),
    );
  });

  test('times out when the provider goes silent', () async {
    AiService.idleTimeout = const Duration(milliseconds: 100);
    AiService.clientFactory = () => MockClient.streaming((request, body) async {
          final controller = StreamController<List<int>>();
          controller.add(utf8.encode('data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n'));
          return http.StreamedResponse(controller.stream, 200, headers: {'content-type': 'text/event-stream'});
        });
    await expectLater(AiService.interpret(grok, 'q'),
        throwsA(isA<AiException>().having((e) => e.message, 'message', contains('stopped responding'))));
  });

  test('an empty answer is an error, not a blank screen', () async {
    AiService.clientFactory = () => MockClient.streaming((r, b) async => sse(['data: [DONE]\n\n']));
    await expectLater(AiService.interpret(grok, 'q'), throwsA(isA<AiException>()));
  });

  test('derives the models URL from the chat endpoint', () {
    expect(AiService.modelsUri('Grok', 'https://api.x.ai/v1/chat/completions').toString(), 'https://api.x.ai/v1/models');
    expect(AiService.modelsUri('Anthropic', 'https://api.anthropic.com/v1/messages').toString(),
        'https://api.anthropic.com/v1/models?limit=1000');
    expect(AiService.modelsUri('Gemini', LlmProviders.endpoints['Gemini']!).toString(),
        'https://generativelanguage.googleapis.com/v1beta/openai/models');
    expect(AiService.modelsUri('Custom', 'http://192.168.1.10:11434/v1/chat/completions').toString(),
        'http://192.168.1.10:11434/v1/models');
  });

  test('lists chat models newest first and drops non-chat models', () async {
    AiService.clientFactory = () => MockClient((request) async {
          expect(request.url.path, '/v1/models');
          return http.Response(
              jsonEncode({
                'data': [
                  {'id': 'grok-4.5', 'created': 100},
                  {'id': 'grok-imagine-image', 'created': 400},
                  {'id': 'grok-4.7', 'created': 300},
                  {'id': 'grok-4.6', 'created': 200},
                ]
              }),
              200);
        });
    expect(await AiService.listModels(grok), ['grok-4.7', 'grok-4.6', 'grok-4.5']);
  });

  test('strips the models/ prefix of Gemini ids', () async {
    final gemini = SettingsState(llmProvider: 'Gemini', apiEndpoint: LlmProviders.endpoints['Gemini']!, apiKey: 'k');
    AiService.clientFactory = () => MockClient((request) async => http.Response(
        jsonEncode({
          'data': [
            {'id': 'models/gemini-3.8-flash'},
            {'id': 'models/gemini-embedding-001'},
          ]
        }),
        200));
    expect(await AiService.listModels(gemini), ['gemini-3.8-flash']);
  });

  test('suggested models fall back when nothing was loaded', () {
    final s = SettingsState(modelCache: const {'Grok': ['grok-9']});
    expect(s.modelsFor('Grok'), ['grok-9']);
    expect(s.modelsFor('DeepSeek'), LlmProviders.models['DeepSeek']);
  });
}
