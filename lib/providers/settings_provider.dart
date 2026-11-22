import 'dart:convert';

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

/// Daily Rashifal notification preferences.
class RashifalPrefs {
  /// Morning notification on/off.
  final bool enabled;
  final int hour;
  final int minute;

  /// Days that get a notification, as [DateTime.weekday] (1 = Monday).
  final Set<int> weekdays;

  /// Kundali used for the notification; null = first profile.
  final int? profileId;

  /// Place for the Panchang, sunrise and muhurats; null = the birth place.
  final String? placeName;
  final double? lat;
  final double? lon;
  final String? tzName;

  /// Run the AI analysis automatically when a day is opened (needs an API key).
  final bool autoAi;

  const RashifalPrefs({
    this.enabled = true,
    this.hour = 8,
    this.minute = 0,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.profileId,
    this.placeName,
    this.lat,
    this.lon,
    this.tzName,
    this.autoAi = true,
  });

  bool get hasPlace => placeName != null && lat != null && lon != null;

  RashifalPrefs copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    int? profileId,
    bool clearProfile = false,
    String? placeName,
    double? lat,
    double? lon,
    String? tzName,
    bool clearPlace = false,
    bool? autoAi,
  }) =>
      RashifalPrefs(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekdays: weekdays ?? this.weekdays,
        profileId: clearProfile ? null : (profileId ?? this.profileId),
        placeName: clearPlace ? null : (placeName ?? this.placeName),
        lat: clearPlace ? null : (lat ?? this.lat),
        lon: clearPlace ? null : (lon ?? this.lon),
        tzName: clearPlace ? null : (tzName ?? this.tzName),
        autoAi: autoAi ?? this.autoAi,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'weekdays': (weekdays.toList()..sort()),
        'profileId': profileId,
        'placeName': placeName,
        'lat': lat,
        'lon': lon,
        'tzName': tzName,
        'autoAi': autoAi,
      };

  factory RashifalPrefs.fromJson(Map<String, dynamic> j) {
    final days = (j['weekdays'] as List?)?.whereType<num>().map((e) => e.toInt()).where((d) => d >= 1 && d <= 7).toSet();
    return RashifalPrefs(
      enabled: j['enabled'] as bool? ?? true,
      hour: ((j['hour'] as num?)?.toInt() ?? 8).clamp(0, 23),
      minute: ((j['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
      weekdays: days ?? const {1, 2, 3, 4, 5, 6, 7},
      profileId: (j['profileId'] as num?)?.toInt(),
      placeName: j['placeName'] as String?,
      lat: (j['lat'] as num?)?.toDouble(),
      lon: (j['lon'] as num?)?.toDouble(),
      tzName: j['tzName'] as String?,
      autoAi: j['autoAi'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) => other is RashifalPrefs && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

class SettingsState {
  // Appearance
  final String chartStyle; // 'North', 'South' or 'East'
  final String themeMode; // 'Cosmic', 'Dark', 'Light'

  /// App language: 'en' or 'hi'.
  final String appLanguage;

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

  /// Daily Rashifal notification preferences.
  final RashifalPrefs rashifal;

  SettingsState({
    this.chartStyle = 'North',
    this.themeMode = 'Cosmic',
    this.appLanguage = 'en',
    this.llmProvider = 'OpenAI',
    this.aiLanguage = 'English',
    this.apiEndpoint = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.modelName = 'gpt-6.1-sol',
    this.modelCache = const {},
    this.calc = CalcConfig.defaults,
    this.rashifal = const RashifalPrefs(),
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
    String? appLanguage,
    String? llmProvider,
    String? aiLanguage,
    String? apiEndpoint,
    String? apiKey,
    String? modelName,
    Map<String, List<String>>? modelCache,
    CalcConfig? calc,
    RashifalPrefs? rashifal,
  }) {
    return SettingsState(
      chartStyle: chartStyle ?? this.chartStyle,
      themeMode: themeMode ?? this.themeMode,
      appLanguage: appLanguage ?? this.appLanguage,
      llmProvider: llmProvider ?? this.llmProvider,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      modelCache: modelCache ?? this.modelCache,
      calc: calc ?? this.calc,
      rashifal: rashifal ?? this.rashifal,
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
      RashifalPrefs? rashifal;
      try {
        final raw = values['rashifalPrefs'];
        if (raw != null) rashifal = RashifalPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
      state = state.copyWith(
        rashifal: rashifal,
        calc: calc,
        modelCache: cache,
        chartStyle: values['chartStyle'],
        themeMode: values['themeMode'],
        appLanguage: values['appLanguage'] == 'hi' ? 'hi' : (values['appLanguage'] == null ? null : 'en'),
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

  /// Switches the app language; the AI answer language follows unless the
  /// user picked a different one.
  Future<void> updateLanguage(String lang) async {
    final follow = state.aiLanguage == 'English' || state.aiLanguage == 'Hindi';
    state = state.copyWith(appLanguage: lang, aiLanguage: follow ? (lang == 'hi' ? 'Hindi' : 'English') : null);
    try {
      await _storage.write(key: 'appLanguage', value: lang);
      if (follow) await _storage.write(key: 'aiLanguage', value: state.aiLanguage);
    } catch (_) {}
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

  Future<void> updateRashifal(RashifalPrefs prefs) async {
    state = state.copyWith(rashifal: prefs);
    try {
      await _storage.write(key: 'rashifalPrefs', value: jsonEncode(prefs.toJson()));
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
