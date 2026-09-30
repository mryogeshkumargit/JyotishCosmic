import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Known LLM providers: default endpoint and suggested models (the model
/// field is free text, so any model the provider offers can be used).
class LlmProviders {
  static const Map<String, String> endpoints = {
    'OpenAI': 'https://api.openai.com/v1/chat/completions',
    'Anthropic': 'https://api.anthropic.com/v1/messages',
    'Gemini': 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
    'DeepSeek': 'https://api.deepseek.com/v1/chat/completions',
    'Grok': 'https://api.x.ai/v1/chat/completions',
    // Any OpenAI-compatible server, e.g. a local Ollama / LM Studio on your network.
    'Custom': 'http://192.168.1.10:11434/v1/chat/completions',
  };

  static const Map<String, List<String>> models = {
    'OpenAI': ['gpt-5', 'gpt-5-mini'],
    'Anthropic': ['claude-opus-5-5', 'claude-sonnet-5-5', 'claude-haiku-4-5'],
    'Gemini': ['gemini-2.5-pro', 'gemini-2.5-flash'],
    'DeepSeek': ['deepseek-chat', 'deepseek-reasoner'],
    'Grok': ['grok-4'],
    'Custom': ['llama3.1', 'qwen2.5'],
  };
}

class SettingsState {
  // Appearance
  final String chartStyle; // 'North', 'South' or 'East'
  final String themeMode; // 'Cosmic', 'Dark', 'Light'

  // AI Config
  final String llmProvider;
  final String aiLanguage;
  final String apiEndpoint;
  final String apiKey;
  final String modelName;

  SettingsState({
    this.chartStyle = 'North',
    this.themeMode = 'Cosmic',
    this.llmProvider = 'OpenAI',
    this.aiLanguage = 'English',
    this.apiEndpoint = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.modelName = 'gpt-5',
  });

  SettingsState copyWith({
    String? chartStyle,
    String? themeMode,
    String? llmProvider,
    String? aiLanguage,
    String? apiEndpoint,
    String? apiKey,
    String? modelName,
  }) {
    return SettingsState(
      chartStyle: chartStyle ?? this.chartStyle,
      themeMode: themeMode ?? this.themeMode,
      llmProvider: llmProvider ?? this.llmProvider,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  final _storage = const FlutterSecureStorage();

  /// Completes once persisted settings have been loaded.
  late Future<void> loaded;

  @override
  SettingsState build() {
    loaded = _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final values = await _storage.readAll();
      String? provider = values['llmProvider'];
      if (provider != null && !LlmProviders.endpoints.containsKey(provider)) provider = null;
      String? endpoint = values['apiEndpoint'];
      // Older versions stored an incomplete Gemini URL that never worked.
      if (provider == 'Gemini' && endpoint != null && !endpoint.contains('/openai/')) {
        endpoint = LlmProviders.endpoints['Gemini'];
      }
      state = state.copyWith(
        chartStyle: values['chartStyle'],
        themeMode: values['themeMode'],
        llmProvider: provider,
        aiLanguage: values['aiLanguage'],
        apiEndpoint: endpoint,
        apiKey: values['apiKey'],
        modelName: values['modelName'],
      );
    } catch (_) {
      // Keep defaults if secure storage is unavailable.
    }
  }

  Future<void> updateAppearance(String style, String theme) async {
    state = state.copyWith(chartStyle: style, themeMode: theme);
    await _storage.write(key: 'chartStyle', value: style);
    await _storage.write(key: 'themeMode', value: theme);
  }

  Future<void> updateAIConfig(String llm, String lang, String endpoint, String key, String model) async {
    state = state.copyWith(
      llmProvider: llm,
      aiLanguage: lang,
      apiEndpoint: endpoint,
      apiKey: key,
      modelName: model,
    );
    await _storage.write(key: 'llmProvider', value: llm);
    await _storage.write(key: 'aiLanguage', value: lang);
    await _storage.write(key: 'apiEndpoint', value: endpoint);
    await _storage.write(key: 'apiKey', value: key);
    await _storage.write(key: 'modelName', value: model);
  }
}
