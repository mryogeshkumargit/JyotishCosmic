import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/calc_config.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Known LLM providers: default endpoint and suggested models. The Settings
/// screen also loads the live model list from the provider (`/models`), and
/// the model field accepts any id, so new models work without an app update.
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
    'OpenAI': ['gpt-6-astra', 'gpt-6.1-sol', 'gpt-6-sol', 'gpt-6-luna'],
    'Anthropic': ['claude-opus-5-5', 'claude-sonnet-5-5', 'claude-fable-5-1', 'claude-haiku-4-5'],
    'Gemini': ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.5-flash', 'gemini-3.1-pro-preview', 'gemini-3.5-flash-lite'],
    'DeepSeek': ['deepseek-v4-pro', 'deepseek-v4-flash'],
    'Grok': ['grok-4.7', 'grok-4.6', 'grok-4.5'],
    'Custom': ['llama3.1', 'qwen2.5'],
  };

  /// Model ids that providers have retired; saved settings using them are
  /// moved to the provider's current default.
  static const Map<String, Set<String>> retired = {
    'Gemini': {'gemini-pro', 'gemini-1.0-pro', 'gemini-1.5-pro', 'gemini-1.5-flash'},
    // Compatibility aliases discontinued by DeepSeek on 24 July 2026.
    'DeepSeek': {'deepseek-chat', 'deepseek-reasoner'},
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

  /// Models last loaded from each provider's `/models` endpoint.
  final Map<String, List<String>> modelCache;

  /// Calculation conventions where traditions differ.
  final CalcConfig calc;

  SettingsState({
    this.chartStyle = 'North',
    this.themeMode = 'Cosmic',
    this.llmProvider = 'OpenAI',
    this.aiLanguage = 'English',
    this.apiEndpoint = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.modelName = 'gpt-6.1-sol',
    this.modelCache = const {},
    this.calc = CalcConfig.defaults,
  });

  /// Models to offer for [provider]: the live list if loaded, else suggestions.
  List<String> modelsFor(String provider) {
    final live = modelCache[provider];
    if (live != null && live.isNotEmpty) return live;
    return LlmProviders.models[provider] ?? const [];
  }

  SettingsState copyWith({
    String? chartStyle,
    String? themeMode,
    String? llmProvider,
    String? aiLanguage,
    String? apiEndpoint,
    String? apiKey,
    String? modelName,
    Map<String, List<String>>? modelCache,
    CalcConfig? calc,
  }) {
    return SettingsState(
      chartStyle: chartStyle ?? this.chartStyle,
      themeMode: themeMode ?? this.themeMode,
      llmProvider: llmProvider ?? this.llmProvider,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      modelCache: modelCache ?? this.modelCache,
      calc: calc ?? this.calc,
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
      String? model = values['modelName'];
      if (provider != null && model != null && (LlmProviders.retired[provider]?.contains(model) ?? false)) {
        model = LlmProviders.models[provider]!.first;
      }
      final cache = <String, List<String>>{
        for (final e in values.entries)
          if (e.key.startsWith('models_') && e.value.isNotEmpty) e.key.substring(7): e.value.split('\n'),
      };
      CalcConfig calc = CalcConfig.defaults;
      final na = values['calc_nodeAspects'];
      final wr = values['calc_warRule'];
      final orb = double.tryParse(values['calc_closeOrb'] ?? '');
      calc = calc.copyWith(
        ayanamsa: values['calc_ayanamsa'],
        trueNode: values['calc_trueNode'] == null ? null : values['calc_trueNode'] == 'true',
        dashaYearDays: double.tryParse(values['calc_dashaYear'] ?? ''),
        karakaScheme: int.tryParse(values['calc_karakas'] ?? ''),
        transitOrb: double.tryParse(values['calc_transitOrb'] ?? ''),
        nodeAspects: NodeAspectRule.values.where((v) => v.name == na).firstOrNull,
        warRule: WarRule.values.where((v) => v.name == wr).firstOrNull,
        closeConjunctionOrb: orb,
      );
      state = state.copyWith(
        calc: calc,
        modelCache: cache,
        chartStyle: values['chartStyle'],
        themeMode: values['themeMode'],
        llmProvider: provider,
        aiLanguage: values['aiLanguage'],
        apiEndpoint: endpoint,
        apiKey: values['apiKey'],
        modelName: model,
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

  Future<void> updateCalc(CalcConfig calc) async {
    state = state.copyWith(calc: calc);
    try {
      await _storage.write(key: 'calc_nodeAspects', value: calc.nodeAspects.name);
      await _storage.write(key: 'calc_warRule', value: calc.warRule.name);
      await _storage.write(key: 'calc_closeOrb', value: calc.closeConjunctionOrb.toString());
      await _storage.write(key: 'calc_ayanamsa', value: calc.ayanamsa);
      await _storage.write(key: 'calc_trueNode', value: calc.trueNode.toString());
      await _storage.write(key: 'calc_dashaYear', value: calc.dashaYearDays.toString());
      await _storage.write(key: 'calc_karakas', value: calc.karakaScheme.toString());
      await _storage.write(key: 'calc_transitOrb', value: calc.transitOrb.toString());
    } catch (_) {}
  }

  /// Remembers the live model list of [provider] (shown in the model picker).
  Future<void> cacheModels(String provider, List<String> models) async {
    state = state.copyWith(modelCache: {...state.modelCache, provider: models});
    try {
      await _storage.write(key: 'models_$provider', value: models.join('\n'));
    } catch (_) {}
  }
}
